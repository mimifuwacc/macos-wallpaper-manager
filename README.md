# Wallpaper Manager

A macOS menu bar app that automatically switches your desktop wallpaper based on each display's orientation. Portrait (rotated) displays get a portrait wallpaper; landscape displays get a landscape one — and it re-applies automatically when you connect, disconnect, rotate, or change the resolution of a display.

## Features

- Lives in the menu bar only — no Dock icon (`LSUIElement`).
- Pick a **portrait** and a **landscape** wallpaper (jpg, jpeg, png, heic).
- **Apply Now** to set wallpapers for the current screen layout.
- **Apply automatically on launch** toggle.
- Automatically re-applies on display connect / disconnect / rotation / resolution change.
- A small **Settings** window with previews, plus the same controls in the menu bar.

A display is treated as **portrait** when `screen.frame.height > screen.frame.width`, otherwise **landscape**.

## Requirements

- macOS 13.0+
- Xcode 15+ (built with Xcode 26)

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

On launch a photo icon appears in the menu bar. Open **Settings…**, choose your portrait and landscape wallpapers, and they are applied immediately.

## How it works

- Wallpapers are set with `NSWorkspace.shared.setDesktopImageURL(_:for:options:)`, one call per `NSScreen`.
- Displays are enumerated via `NSScreen.screens`.
- Layout changes are detected through `NSApplication.didChangeScreenParametersNotification`.
- Selected image URLs and the auto-apply flag are persisted in `UserDefaults`.

## Project structure

```
WallpaperManager/
├── WallpaperManagerApp.swift       # @main SwiftUI App (no window; Settings scene)
├── AppDelegate.swift               # Status item, menu, screen-change observer
├── WallpaperController.swift       # Selection, persistence, applying (ObservableObject)
├── SettingsView.swift              # SwiftUI settings UI
└── SettingsWindowController.swift  # Hosts the settings view in an NSWindow
```

## Notes

- App Sandbox is disabled, which is what lets the app write desktop image settings freely.
- Errors are logged with `print`.
