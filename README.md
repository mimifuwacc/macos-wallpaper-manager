# Wallpaper Manager

A headless macOS app that sets your desktop wallpaper per display orientation — portrait displays get a portrait image, landscape displays get a landscape one — and re-applies automatically when displays change. Or fill every display with a single solid color instead.

## Features

- Separate **portrait** and **landscape** wallpapers (jpg, png, heic), or a **solid color** on every display.
- Re-applies automatically on display connect / disconnect / rotate / resolution change.
- **Apply on launch** and **launch at login** toggles.
- Runs in the background with no Dock or menu bar icon. Re-launch the app to open **Settings**; quit from there.

## Requirements

- macOS 26.0+ and Xcode 26+ (uses the Liquid Glass APIs).

## Install

Via Homebrew:

```sh
brew install --cask mimifuwacc/tap/wallpaper-manager
```

Or build it yourself:

```sh
xcodebuild -project WallpaperManager.xcodeproj -scheme WallpaperManager -configuration Debug build
```

## How it works

Wallpapers are applied per `NSScreen` with `NSWorkspace.setDesktopImageURL`; a display counts as portrait when its height exceeds its width. Layout changes are picked up via `didChangeScreenParametersNotification`, and settings persist in `UserDefaults`. App Sandbox is disabled so the app can write desktop image settings.
