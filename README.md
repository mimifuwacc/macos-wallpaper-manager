# Wallpaper Manager

A macOS background app that automatically switches your desktop wallpaper based on each display's orientation. Portrait (rotated) displays get a portrait wallpaper; landscape displays get a landscape one — and it re-applies automatically when you connect, disconnect, rotate, or change the resolution of a display.

## Features

- Runs headless in the background — no Dock icon and no menu bar item (`LSUIElement`).
- Pick a **portrait** and a **landscape** wallpaper (jpg, jpeg, png, heic).
- **Apply Now** to set wallpapers for the current screen layout.
- **Apply automatically on launch** toggle.
- **Launch at login** toggle (registers via `SMAppService`).
- Automatically re-applies on display connect / disconnect / rotation / resolution change.
- A **Settings** window with a **Liquid Glass** UI and orientation-aware previews. Launch the app (or re-launch it from Finder/Spotlight) to open Settings; quit from the **Quit** button there.

A display is treated as **portrait** when `screen.frame.height > screen.frame.width`, otherwise **landscape**.

## Requirements

- macOS 26.0+ (uses the Liquid Glass APIs, e.g. `glassEffect`)
- Xcode 26+

## Build & Run

Open the project in Xcode and run:

```sh
open WallpaperManager.xcodeproj
```

Or build from the command line:

```sh
xcodebuild -project WallpaperManager.xcodeproj -scheme WallpaperManager -configuration Debug build
```

The signed app is then under your DerivedData folder:

```sh
open ~/Library/Developer/Xcode/DerivedData/WallpaperManager-*/Build/Products/Debug/WallpaperManager.app
```

On first launch the **Settings** window opens. Choose your portrait and landscape wallpapers and they are applied immediately. The app then keeps running in the background with no Dock or menu bar presence. To change settings later, launch the app again (Finder/Spotlight) — it reopens the Settings window. When launched at login it starts silently without opening Settings. Quit from the **Quit** button in the Settings window.

## How it works

- Wallpapers are set with `NSWorkspace.shared.setDesktopImageURL(_:for:options:)`, one call per `NSScreen`.
- Displays are enumerated via `NSScreen.screens`.
- Layout changes are detected through `NSApplication.didChangeScreenParametersNotification`.
- Selected image URLs and the auto-apply flag are persisted in `UserDefaults`.

## Project structure

```
WallpaperManager/
├── WallpaperManagerApp.swift       # @main SwiftUI App (no window; Settings scene)
├── AppDelegate.swift               # Background agent lifecycle, screen-change observer
├── WallpaperController.swift       # Selection, persistence, applying (ObservableObject)
├── SettingsView.swift              # SwiftUI settings UI
└── SettingsWindowController.swift  # Hosts the settings view in an NSWindow
```

## Notes

- App Sandbox is disabled, which is what lets the app write desktop image settings freely.
- Errors are logged with `print`.
