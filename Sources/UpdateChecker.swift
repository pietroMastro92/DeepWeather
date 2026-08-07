import Foundation
import Observation
import AppKit
import UserNotifications

@MainActor
@Observable
final class UpdateChecker {

    // MARK: - Public state

    private(set) var latestVersion: String?
    private(set) var releaseNotes: String?
    private(set) var downloadURL: String?
    private(set) var isChecking = false
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var errorMessage: String?

    var updateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        return Self.isNewer(latest, than: Self.currentVersion)
    }

    /// The running app's version, sourced from the Info.plist
    /// `CFBundleShortVersionString` key.
    static let currentVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }()

    // MARK: - Configuration

    private static let repo = "pietroMastro92/DeepWeather"
    private static let checkIntervalSeconds: TimeInterval = 3600 // 1 h
    private var autoCheckTask: Task<Void, Never>?

    /// Key used to remember which version we already notified about.
    private static let notifiedVersionKey = "UpdateChecker.notifiedVersion"

    // MARK: - Lifecycle

    /// Begin periodic update checks. Safe to call more than once.
    func startPeriodicCheck() {
        guard autoCheckTask == nil else { return }
        Task { await checkForUpdates() }
        autoCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.checkIntervalSeconds))
                guard !Task.isCancelled else { break }
                await self?.checkForUpdates()
            }
        }
    }

    // MARK: - Check for updates

    func checkForUpdates() async {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil
        defer { isChecking = false }

        do {
            let release = try await fetchLatestRelease()
            let version = release.tagName
                .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            latestVersion = version
            releaseNotes = release.body
            downloadURL = release.assets
                .first { $0.name.hasSuffix(".zip") }?
                .browserDownloadUrl

            if updateAvailable {
                await sendUpdateNotificationOnce(version: version)
            }
        } catch {
            errorMessage = "Could not check for updates."
        }
    }

    // MARK: - Download & install

    func downloadAndInstall() async {
        guard let urlString = downloadURL,
              let url = URL(string: urlString)
        else {
            errorMessage = "No download URL available."
            return
        }

        isDownloading = true
        downloadProgress = 0
        errorMessage = nil

        do {
            // 1. Download the zip
            let (tempZip, _) = try await URLSession.shared.download(from: url)
            downloadProgress = 0.4

            // 2. Unzip to a temporary directory
            let extractDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("DeepWeatherUpdate-\(UUID().uuidString)")
            try FileManager.default.createDirectory(
                at: extractDir,
                withIntermediateDirectories: true
            )

            try await unzip(tempZip, to: extractDir)
            downloadProgress = 0.7

            // 3. Locate the .app bundle inside the extracted tree
            guard let newApp = try findAppBundle(in: extractDir) else {
                throw UpdateError.appNotFound
            }
            downloadProgress = 0.8

            // 4. Safety check: verify the downloaded binary actually has a
            //    higher version than the running app. This prevents infinite
            //    update loops when the release asset was built before a
            //    version bump.
            let newPlistURL = newApp.appendingPathComponent("Contents/Info.plist")
            guard let newPlist = NSDictionary(contentsOf: newPlistURL),
                  let newVersion = newPlist["CFBundleShortVersionString"] as? String,
                  Self.isNewer(newVersion, than: Self.currentVersion)
            else {
                // Cleanup temp files
                try? FileManager.default.removeItem(at: extractDir)
                throw UpdateError.sameOrOlderVersion
            }

            // 5. Prepare a shell script that replaces the bundle after quit
            let currentApp = Bundle.main.bundleURL
            let script = updaterScript(
                newAppPath: newApp.path(percentEncoded: false),
                currentAppPath: currentApp.path(percentEncoded: false),
                pid: ProcessInfo.processInfo.processIdentifier
            )

            let scriptURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("deepweather_updater.sh")
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: scriptURL.path(percentEncoded: false)
            )
            downloadProgress = 1.0

            // 6. Launch the updater script and quit
            let launcher = Process()
            launcher.executableURL = URL(fileURLWithPath: "/bin/zsh")
            launcher.arguments = [scriptURL.path(percentEncoded: false)]
            try launcher.run()

            try? await Task.sleep(for: .milliseconds(300))
            NSApplication.shared.terminate(nil)

        } catch {
            errorMessage = "Update failed: \(error.localizedDescription)"
            isDownloading = false
            downloadProgress = 0
        }
    }

    // MARK: - GitHub API model

    private struct GitHubRelease: Decodable {
        let tagName: String
        let name: String?
        let body: String?
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name, body, assets
        }

        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: String
            let size: Int

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
                case size
            }
        }
    }

    private enum UpdateError: LocalizedError {
        case extractionFailed
        case appNotFound
        case sameOrOlderVersion

        var errorDescription: String? {
            switch self {
            case .extractionFailed:
                return "Failed to extract update archive."
            case .appNotFound:
                return "App bundle not found in download."
            case .sameOrOlderVersion:
                return "Downloaded version is not newer than the installed version."
            }
        }
    }

    // MARK: - Networking

    private func fetchLatestRelease() async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")!
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("DeepWeather/\(Self.currentVersion)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    // MARK: - Extraction helpers

    private nonisolated func unzip(_ source: URL, to destination: URL) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = [
                "-o", source.path(percentEncoded: false),
                "-d", destination.path(percentEncoded: false)
            ]
            process.standardOutput = nil
            process.standardError = nil
            process.terminationHandler = { p in
                if p.terminationStatus == 0 {
                    cont.resume()
                } else {
                    cont.resume(throwing: UpdateError.extractionFailed)
                }
            }
            do {
                try process.run()
            } catch {
                cont.resume(throwing: error)
            }
        }
    }

    private nonisolated func findAppBundle(in directory: URL) throws -> URL? {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "app" {
                return fileURL
            }
        }
        return nil
    }

    // MARK: - Updater script

    private nonisolated func updaterScript(
        newAppPath: String,
        currentAppPath: String,
        pid: Int32
    ) -> String {
        """
        #!/bin/zsh
        # DeepWeather self-updater — generated at runtime
        set -euo pipefail

        # Wait for the running instance to exit
        while kill -0 \(pid) 2>/dev/null; do sleep 0.3; done

        # Replace the app bundle
        rm -rf "\(currentAppPath)"
        cp -R "\(newAppPath)" "\(currentAppPath)"

        # Remove Gatekeeper quarantine attribute
        xattr -dr com.apple.quarantine "\(currentAppPath)" 2>/dev/null || true

        # Relaunch
        open "\(currentAppPath)"

        # Cleanup this script
        rm -f "$0"
        """
    }

    // MARK: - macOS notification (one-shot per version)

    /// Sends a macOS notification only once per discovered version.
    /// Subsequent periodic checks for the same version stay silent.
    private func sendUpdateNotificationOnce(version: String) async {
        let alreadyNotified = UserDefaults.standard
            .string(forKey: Self.notifiedVersionKey)
        guard alreadyNotified != version else { return }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
        }

        let current = await center.notificationSettings()
        guard current.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "DeepWeather Update"
        content.body = "Version \(version) is available. Open the app to install."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "update-\(version)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)

        UserDefaults.standard.set(version, forKey: Self.notifiedVersionKey)
    }

    // MARK: - Semver comparison

    /// Returns `true` when `lhs` is a higher semantic version than `rhs`.
    static func isNewer(_ lhs: String, than rhs: String) -> Bool {
        let lParts = lhs.split(separator: ".").compactMap { Int($0) }
        let rParts = rhs.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(lParts.count, rParts.count) {
            let l = i < lParts.count ? lParts[i] : 0
            let r = i < rParts.count ? rParts[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
