import AppKit
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
    }

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

    init() {
        // didSet is not triggered for assignments inside init, so there is no double write.
        portraitURL = defaults.url(forKey: Keys.portrait)
        landscapeURL = defaults.url(forKey: Keys.landscape)
        autoApplyOnLaunch = defaults.bool(forKey: Keys.autoApply)
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
}
