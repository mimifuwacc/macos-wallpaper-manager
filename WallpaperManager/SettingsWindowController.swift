import AppKit
import SwiftUI

/// Hosts the SwiftUI settings view in a standalone window.
/// Reused across opens; not released on close so state is preserved.
final class SettingsWindowController: NSWindowController {

    convenience init(controller: WallpaperController) {
        let hosting = NSHostingController(rootView: SettingsView(controller: controller))
        let window = NSWindow(contentViewController: hosting)
        window.title = "Wallpaper Manager Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()
        self.init(window: window)
    }

    /// Bring the settings window to the front (activating the accessory app first).
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}
