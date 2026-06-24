import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let controller = WallpaperController()
    private lazy var settingsWindowController = SettingsWindowController(controller: controller)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Stay out of the Dock and live in the menu bar.
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        observeScreenChanges()

        // If auto-apply is enabled, apply for the current screen layout on launch.
        if controller.autoApplyOnLaunch {
            controller.applyWallpapers()
        }
    }

    // MARK: - Menu bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "photo.on.rectangle",
            accessibilityDescription: "Wallpaper Manager"
        )
        // Clicking the menu bar icon opens the settings window directly (no dropdown menu).
        statusItem.button?.target = self
        statusItem.button?.action = #selector(openSettings)
    }

    // MARK: - Screen layout observation

    private func observeScreenChanges() {
        // Fires on connect/disconnect, rotation, resolution changes, etc.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screenParametersChanged(_ notification: Notification) {
        print("Screen layout changed; re-applying wallpapers")
        controller.applyWallpapers()
    }

    // MARK: - Actions

    @objc private func openSettings() {
        settingsWindowController.show()
    }
}
