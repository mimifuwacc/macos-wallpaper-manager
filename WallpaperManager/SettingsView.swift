import SwiftUI

/// Settings window opened from the menu bar.
/// Lets the user pick/clear the portrait and landscape wallpapers,
/// toggle auto-apply, and apply immediately.
struct SettingsView: View {
    @ObservedObject var controller: WallpaperController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Wallpaper Settings")
                .font(.title2)
                .bold()

            wallpaperSection(
                title: "Portrait Wallpaper",
                subtitle: "Applied to portrait displays (height > width)",
                url: controller.portraitURL,
                onSelect: { selectPortrait() },
                onClear: { controller.portraitURL = nil }
            )

            wallpaperSection(
                title: "Landscape Wallpaper",
                subtitle: "Applied to landscape displays",
                url: controller.landscapeURL,
                onSelect: { selectLandscape() },
                onClear: { controller.landscapeURL = nil }
            )

            Divider()

            Toggle("Apply automatically on launch", isOn: $controller.autoApplyOnLaunch)

            HStack {
                Spacer()
                Button("Apply Now") {
                    controller.applyWallpapers()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }

    // MARK: - Components

    @ViewBuilder
    private func wallpaperSection(
        title: String,
        subtitle: String,
        url: URL?,
        onSelect: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                preview(for: url)

                VStack(alignment: .leading, spacing: 6) {
                    Text(url?.lastPathComponent ?? "Not selected")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(url == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))

                    HStack {
                        Button("Choose…", action: onSelect)
                        if url != nil {
                            Button("Clear", action: onClear)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func preview(for url: URL?) -> some View {
        Group {
            if let url, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .frame(width: 96, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 6))
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
