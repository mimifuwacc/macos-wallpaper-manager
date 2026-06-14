import SwiftUI

@main
struct WallpaperManagerApp: App {
    // This is a menu bar app: it owns no window and manages the status item in AppDelegate.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Use a Settings scene with no content so no window is shown on launch (paired with LSUIElement).
        Settings {
            EmptyView()
        }
    }
}
