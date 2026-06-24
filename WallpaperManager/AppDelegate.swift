import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let controller = WallpaperController()
    private lazy var settingsWindowController = SettingsWindowController(controller: controller)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Headless background agent: no Dock icon, no menu bar item.
        NSApp.setActivationPolicy(.accessory)

        observeScreenChanges()

        // If auto-apply is enabled, apply for the current screen layout on launch.
        if controller.autoApplyOnLaunch {
            controller.applyWallpapers()
        }

        // Stay silent when launched at login; only show settings when the
        // user opens the app themselves (first run or a manual re-launch).
        if !launchedAsLoginItem {
            settingsWindowController.show()
        }
    }

    /// Re-launching the app while it is already running (e.g. double-clicking it
    /// in Finder) reopens the settings window instead of starting a new process.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settingsWindowController.show()
        return true
    }

    // MARK: - Launch detection

    /// Whether this launch was triggered by the login-item registration rather
    /// than by the user. Uses the AppleEvent that launched the app.
    private var launchedAsLoginItem: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventID == kAEOpenApplication else {
            return false
        }
        return event.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
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
}
