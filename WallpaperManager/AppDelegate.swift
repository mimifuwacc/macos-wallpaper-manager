import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    private var statusItem: NSStatusItem!
    private var autoApplyMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!
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
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Choose Portrait Wallpaper…", action: #selector(selectPortrait), keyEquivalent: "")
        menu.addItem(withTitle: "Choose Landscape Wallpaper…", action: #selector(selectLandscape), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Apply Now", action: #selector(applyNow), keyEquivalent: "")

        autoApplyMenuItem = NSMenuItem(
            title: "Apply Automatically on Launch",
            action: #selector(toggleAutoApply),
            keyEquivalent: ""
        )
        autoApplyMenuItem.state = controller.autoApplyOnLaunch ? .on : .off
        menu.addItem(autoApplyMenuItem)

        launchAtLoginMenuItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.state = controller.launchAtLogin ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")

        // Route every actionable item to self.
        for item in menu.items where item.action != nil {
            item.target = self
        }
        return menu
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        // Keep the checkmarks in sync with changes made from the settings window.
        autoApplyMenuItem.state = controller.autoApplyOnLaunch ? .on : .off
        launchAtLoginMenuItem.state = controller.launchAtLogin ? .on : .off
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

    // MARK: - Menu actions

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func selectPortrait() {
        if let url = controller.chooseImageURL() {
            controller.portraitURL = url
            controller.applyWallpapers()
        }
    }

    @objc private func selectLandscape() {
        if let url = controller.chooseImageURL() {
            controller.landscapeURL = url
            controller.applyWallpapers()
        }
    }

    @objc private func applyNow() {
        controller.applyWallpapers()
    }

    @objc private func toggleAutoApply() {
        controller.autoApplyOnLaunch.toggle()
        autoApplyMenuItem.state = controller.autoApplyOnLaunch ? .on : .off
    }

    @objc private func toggleLaunchAtLogin() {
        controller.launchAtLogin.toggle()
        // Read back the controller value: registration may have failed and reverted.
        launchAtLoginMenuItem.state = controller.launchAtLogin ? .on : .off
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
