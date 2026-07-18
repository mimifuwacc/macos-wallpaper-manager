import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

/// Handles selecting, persisting, and applying wallpapers.
/// Settings are stored in UserDefaults and applied via NSWorkspace.
/// It is an ObservableObject so the settings window can observe it.
final class WallpaperController: ObservableObject {

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let portrait = "portraitWallpaperURL"
        static let landscape = "landscapeWallpaperURL"
        static let autoApply = "autoApplyOnLaunch"
        static let useSolidColor = "useSolidColor"
        static let solidColor = "solidColorURL"
    }

    /// Directory where macOS ships its built-in solid-color wallpapers.
    private static let solidColorsDirectory = URL(
        fileURLWithPath: "/System/Library/Desktop Pictures/Solid Colors", isDirectory: true)

    // MARK: - Stored values (synced to UserDefaults on change)

    /// Wallpaper image URL for portrait displays.
    @Published var portraitURL: URL? {
        didSet { defaults.set(portraitURL, forKey: Keys.portrait) }
    }

    /// Wallpaper image URL for landscape displays.
    @Published var landscapeURL: URL? {
        didSet { defaults.set(landscapeURL, forKey: Keys.landscape) }
    }

    /// Whether to apply automatically on launch.
    @Published var autoApplyOnLaunch: Bool {
        didSet { defaults.set(autoApplyOnLaunch, forKey: Keys.autoApply) }
    }

    /// Whether to use a single solid color on every display instead of images.
    @Published var useSolidColor: Bool {
        didSet { defaults.set(useSolidColor, forKey: Keys.useSolidColor) }
    }

    /// The chosen solid-color wallpaper, drawn from the colors macOS ships.
    @Published var solidColorURL: URL? {
        didSet { defaults.set(solidColorURL, forKey: Keys.solidColor) }
    }

    /// Solid-color wallpapers bundled with macOS, sorted by display name.
    let solidColors: [SolidColorOption] = WallpaperController.loadSolidColors()

    /// Whether the app is registered to launch automatically at login.
    /// Backed by the system login-item registration rather than UserDefaults.
    @Published var launchAtLogin: Bool {
        didSet { applyLaunchAtLogin() }
    }

    init() {
        // didSet is not triggered for assignments inside init, so there is no double write.
        portraitURL = defaults.url(forKey: Keys.portrait)
        landscapeURL = defaults.url(forKey: Keys.landscape)
        autoApplyOnLaunch = defaults.bool(forKey: Keys.autoApply)
        useSolidColor = defaults.bool(forKey: Keys.useSolidColor)
        solidColorURL = defaults.url(forKey: Keys.solidColor)
        // The system registration is the source of truth for the login item.
        launchAtLogin = SMAppService.mainApp.status == .enabled

        // Fall back to a sensible built-in color the first time solid mode is used.
        if solidColorURL == nil {
            solidColorURL = Self.preferredDefaultColor(from: solidColors)?.url
        }
    }

    // MARK: - Solid colors

    /// Enumerate the solid-color wallpapers macOS ships in its Desktop Pictures folder.
    private static func loadSolidColors() -> [SolidColorOption] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: solidColorsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles])) ?? []

        return contents
            .filter { $0.pathExtension.lowercased() == "png" }
            .map { SolidColorOption(name: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Pick a neutral default color, preferring familiar macOS grays when present.
    private static func preferredDefaultColor(from colors: [SolidColorOption]) -> SolidColorOption? {
        let preferred = ["Space Gray", "Space Gray Pro", "Stone", "Silver", "Black"]
        for name in preferred {
            if let match = colors.first(where: { $0.name == name }) { return match }
        }
        return colors.first
    }

    // MARK: - Launch at login

    /// Register or unregister the app as a login item to match `launchAtLogin`.
    private func applyLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                if service.status != .enabled {
                    try service.register()
                }
            } else if service.status == .enabled {
                try service.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            // Reflect the actual system state if the change didn't take effect.
            launchAtLogin = service.status == .enabled
        }
    }

    // MARK: - Image selection

    /// Show an NSOpenPanel to pick an image and return the chosen URL, or nil if cancelled.
    func chooseImageURL() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        // Allow jpg, jpeg, png, heic (.jpeg covers both jpg and jpeg).
        panel.allowedContentTypes = [.jpeg, .png, .heic]

        // This is an accessory app, so activate explicitly to bring the panel to the front.
        NSApp.activate(ignoringOtherApps: true)

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    // MARK: - Applying

    /// Set the wallpaper for every connected display based on its orientation.
    func applyWallpapers() {
        if useSolidColor {
            applySolidColor()
            return
        }

        let workspace = NSWorkspace.shared

        for screen in NSScreen.screens {
            // Treat a display as portrait when its height is greater than its width.
            let isPortrait = screen.frame.height > screen.frame.width
            guard let url = isPortrait ? portraitURL : landscapeURL else {
                print("No wallpaper set, skipping: \(isPortrait ? "portrait" : "landscape") screen=\(screen.localizedName)")
                continue
            }

            do {
                try workspace.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                print("Failed to set wallpaper screen=\(screen.localizedName): \(error)")
            }
        }
    }

    /// Apply the chosen solid color to every connected display, regardless of orientation.
    private func applySolidColor() {
        guard let url = solidColorURL else {
            print("Solid color mode is on but no color is selected")
            return
        }

        let workspace = NSWorkspace.shared
        for screen in NSScreen.screens {
            do {
                try workspace.setDesktopImageURL(url, for: screen, options: [:])
            } catch {
                print("Failed to set solid color screen=\(screen.localizedName): \(error)")
            }
        }
    }
}

/// A solid-color wallpaper shipped with macOS, identified by its image URL.
struct SolidColorOption: Identifiable, Hashable {
    let name: String
    let url: URL
    var id: URL { url }
}
