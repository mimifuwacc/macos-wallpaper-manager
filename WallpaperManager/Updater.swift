import AppKit

/// Lightweight self-updater: checks GitHub Releases and, if a newer DMG exists,
/// downloads it and swaps the running app in place.
@MainActor
final class Updater: ObservableObject {
    enum Status: Equatable {
        case idle
        case checking
        case upToDate
        case available(version: String)
        case downloading
        case failed(String)
    }

    @Published private(set) var status: Status = .idle

    private let repo = "mimifuwacc/macos-wallpaper-manager"

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Check for updates. When `silent`, the "up to date" dialog is suppressed
    /// (used for the automatic check on launch).
    func check(silent: Bool) {
        guard status != .checking, status != .downloading else { return }
        status = .checking
        Task { await performCheck(silent: silent) }
    }

    private func performCheck(silent: Bool) async {
        do {
            let release = try await fetchLatestRelease()
            let latest = normalize(release.tag_name)
            guard let asset = release.assets.first(where: { $0.name.hasSuffix(".dmg") }),
                  let url = URL(string: asset.browser_download_url) else {
                status = .failed("No DMG found in the latest release")
                return
            }

            if isNewer(latest, than: normalize(currentVersion)) {
                status = .available(version: latest)
                promptInstall(version: latest, url: url)
            } else {
                status = .upToDate
                if !silent {
                    showInfo("You're up to date", "Wallpaper Manager \(currentVersion) is the latest version.")
                }
            }
        } catch {
            status = .failed(error.localizedDescription)
            if !silent { showInfo("Update check failed", error.localizedDescription) }
        }
    }

    // MARK: - GitHub API

    private struct GHRelease: Decodable {
        let tag_name: String
        let assets: [GHAsset]
    }
    private struct GHAsset: Decodable {
        let name: String
        let browser_download_url: String
    }

    private func fetchLatestRelease() async throws -> GHRelease {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WallpaperManager", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Updater", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not reach the GitHub API"])
        }
        return try JSONDecoder().decode(GHRelease.self, from: data)
    }

    // MARK: - Version comparison

    private func normalize(_ v: String) -> String {
        v.hasPrefix("v") ? String(v.dropFirst()) : v
    }

    private func isNewer(_ a: String, than b: String) -> Bool {
        let lhs = a.split(separator: ".").map { Int($0) ?? 0 }
        let rhs = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(lhs.count, rhs.count) {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    // MARK: - Install

    private func promptInstall(version: String, url: URL) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "A new version is available"
        alert.informativeText = "Wallpaper Manager \(version) is available (you have \(currentVersion)).\nUpdate now?"
        alert.addButton(withTitle: "Update Now")
        alert.addButton(withTitle: "Later")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else {
            status = .idle
            return
        }
        status = .downloading
        Task { await downloadAndInstall(url: url) }
    }

    private func downloadAndInstall(url: URL) async {
        do {
            let (tmp, _) = try await URLSession.shared.download(from: url)
            let dmg = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("WallpaperManager-update.dmg")
            try? FileManager.default.removeItem(at: dmg)
            try FileManager.default.moveItem(at: tmp, to: dmg)
            try installFromDMG(dmg)
            // On success this launches a swap script and terminates the app.
        } catch {
            status = .failed(error.localizedDescription)
            showInfo("Update failed", error.localizedDescription)
        }
    }

    private func installFromDMG(_ dmg: URL) throws {
        let mount = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("wm-mnt-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: mount, withIntermediateDirectories: true)

        // Mount the DMG.
        guard Shell.run("/usr/bin/hdiutil",
                        ["attach", "-nobrowse", "-mountpoint", mount.path, dmg.path]).status == 0 else {
            throw NSError(domain: "Updater", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to mount the update DMG"])
        }

        let newApp = mount.appendingPathComponent("WallpaperManager.app").path
        let currentApp = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier

        // Wait for this process to exit, swap the app, strip quarantine, relaunch.
        let script = """
        #!/bin/bash
        while /bin/kill -0 \(pid) 2>/dev/null; do /bin/sleep 0.3; done
        /bin/rm -rf "\(currentApp)"
        /bin/cp -R "\(newApp)" "\(currentApp)"
        /usr/bin/xattr -dr com.apple.quarantine "\(currentApp)" 2>/dev/null
        /usr/bin/hdiutil detach "\(mount.path)" 2>/dev/null
        /bin/rm -f "\(dmg.path)"
        /usr/bin/open "\(currentApp)"
        """
        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("wallpapermanager-update.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptURL.path]
        try task.run() // Detached; do not wait.

        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private func showInfo(_ title: String, _ body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
