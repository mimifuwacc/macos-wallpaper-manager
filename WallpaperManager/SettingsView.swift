import SwiftUI

/// Settings window opened when the app is launched.
/// Lets the user pick/clear the portrait and landscape wallpapers,
/// toggle auto-apply and launch-at-login, apply immediately, or quit.
struct SettingsView: View {
    @ObservedObject var controller: WallpaperController
    @ObservedObject var updater: Updater

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    wallpaperCard(
                        title: "Portrait",
                        subtitle: "Used on displays taller than they are wide",
                        systemImage: "rectangle.portrait",
                        previewSize: CGSize(width: 80, height: 120),
                        url: controller.portraitURL,
                        onSelect: selectPortrait,
                        onClear: { controller.portraitURL = nil }
                    )

                    wallpaperCard(
                        title: "Landscape",
                        subtitle: "Used on standard wide displays",
                        systemImage: "rectangle",
                        previewSize: CGSize(width: 150, height: 94),
                        url: controller.landscapeURL,
                        onSelect: selectLandscape,
                        onClear: { controller.landscapeURL = nil }
                    )

                    optionsCard

                    updatesCard
                }
                .padding(20)
            }

            footer
        }
        .frame(width: 480, height: 600)
        .background(backgroundFill)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 52, height: 52)
                .iconSurface()

            VStack(alignment: .leading, spacing: 2) {
                Text("Wallpaper Manager")
                    .font(.title2.weight(.semibold))
                Text("Orientation-aware desktop wallpapers")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    // MARK: - Wallpaper card

    private func wallpaperCard(
        title: String,
        subtitle: String,
        systemImage: String,
        previewSize: CGSize,
        url: URL?,
        onSelect: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .center, spacing: 16) {
                preview(for: url, size: previewSize)

                VStack(alignment: .leading, spacing: 10) {
                    Text(url?.lastPathComponent ?? "No image selected")
                        .font(.subheadline)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .foregroundStyle(url == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))

                    HStack(spacing: 8) {
                        Button("Choose…", action: onSelect)
                        if url != nil {
                            Button("Clear", role: .destructive, action: onClear)
                        }
                    }
                    .controlSize(.small)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private func preview(for url: URL?, size: CGSize) -> some View {
        Group {
            if let url, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(.quaternary)
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }

    // MARK: - Options card

    private var optionsCard: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $controller.autoApplyOnLaunch) {
                optionLabel("Apply automatically on launch",
                            subtitle: "Set wallpapers as soon as the app starts")
            }
            .padding(.vertical, 12)

            Divider()

            Toggle(isOn: $controller.launchAtLogin) {
                optionLabel("Launch at login",
                            subtitle: "Run quietly in the background after you sign in")
            }
            .padding(.vertical, 12)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 18)
        .cardSurface()
    }

    private func optionLabel(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Updates card

    private var updatesCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Updates")
                Text(updateStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if updaterIsBusy {
                ProgressView().controlSize(.small)
            }

            Button("Check for Updates") {
                updater.check(silent: false)
            }
            .controlSize(.small)
            .disabled(updaterIsBusy)
        }
        .padding(18)
        .cardSurface()
    }

    private var updateStatusText: String {
        switch updater.status {
        case .idle, .failed: return "Version \(updater.currentVersion)"
        case .checking: return "Checking…"
        case .upToDate: return "Up to date (\(updater.currentVersion))"
        case .available(let v): return "Version \(v) is available"
        case .downloading: return "Downloading…"
        }
    }

    private var updaterIsBusy: Bool {
        updater.status == .checking || updater.status == .downloading
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("Quit", role: .destructive) {
                NSApp.terminate(nil)
            }

            Spacer()

            Button("Apply Now") {
                controller.applyWallpapers()
            }
            .prominentGlassButton()
            .keyboardShortcut(.defaultAction)
        }
        .controlSize(.large)
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var backgroundFill: some ShapeStyle {
        .background
    }

    // MARK: - Actions

    private func selectPortrait() {
        if let url = controller.chooseImageURL() {
            controller.portraitURL = url
            controller.applyWallpapers()
        }
    }

    private func selectLandscape() {
        if let url = controller.chooseImageURL() {
            controller.landscapeURL = url
            controller.applyWallpapers()
        }
    }
}

// MARK: - Liquid Glass helpers

private extension View {
    /// Glass surface for content cards.
    /// Uses Liquid Glass on macOS 26 (Tahoe); earlier releases lack the glass
    /// APIs, so they fall back to a translucent material in the same shape.
    @ViewBuilder
    func cardSurface(cornerRadius: CGFloat = 16) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    /// Circular glass surface for the header icon.
    @ViewBuilder
    func iconSurface() -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: Circle())
        } else {
            background(.regularMaterial, in: Circle())
        }
    }

    /// Prominent action button: Liquid Glass on Tahoe, bordered elsewhere.
    @ViewBuilder
    func prominentGlassButton() -> some View {
        if #available(macOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
