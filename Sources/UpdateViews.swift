import SwiftUI

// MARK: - Update banner (shown in the main panel)

struct UpdateBannerView: View {
    let version: String
    let isDownloading: Bool
    let progress: Double
    let onUpdate: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 1) {
                Text("Update available")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("v\(version)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDownloading {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                Text("Installing…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Button("Update", action: onUpdate)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(8)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Version row (shown in Settings)

struct VersionInfoView: View {
    let currentVersion: String
    let latestVersion: String?
    let updateAvailable: Bool
    let isChecking: Bool
    let onCheck: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("About")
                .font(.callout)

            HStack {
                Text("DeepWeather v\(currentVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if isChecking {
                    ProgressView()
                        .controlSize(.mini)
                } else if updateAvailable, let latest = latestVersion {
                    Text("v\(latest) available")
                        .font(.caption2)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                } else if latestVersion != nil {
                    Text("Up to date")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Button(action: onCheck) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
                .help("Check for updates")
                .disabled(isChecking)
            }
        }
    }
}
