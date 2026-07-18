# Contributing

Thanks for your interest in improving Wallpaper Manager! This is a small macOS app, so the process is light.

## Requirements

- macOS 26.0+
- Xcode 26+ (for the macOS 26 SDK and Liquid Glass APIs)

## Getting started

```sh
git clone git@github.com:mimifuwacc/macos-wallpaper-manager.git
cd macos-wallpaper-manager
open WallpaperManager.xcodeproj
```

Build and run from Xcode with ⌘R, or from the command line:

```sh
xcodebuild -project WallpaperManager.xcodeproj -scheme WallpaperManager -configuration Debug build
```

## Making changes

1. Branch off `main` with a short, descriptive name (e.g. `solid-color-wallpaper`, `docs-maintenance`).
2. Keep each PR focused on one thing. Match the style of the surrounding code — small, commented, no new dependencies unless there's a clear reason.
3. Build in Xcode and confirm the app still launches and applies wallpapers before opening a PR.
4. Open a pull request against `main` and fill in the template. Add a screenshot for any UI change.

## Releases

Releases are automated by `.github/workflows/release.yml`. Publishing a GitHub Release with a `vX.Y.Z` tag on `main` builds the app, attaches a DMG, and bumps the Homebrew cask — no manual version bump in the project is needed.
