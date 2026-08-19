import Foundation
import AppKit
import UserNotifications

@MainActor
enum UpdateChecker {
    private struct GitHubRelease: Codable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }

    private static let releasesURL = URL(string: "https://api.github.com/repos/anasubaid19/fomo-doro/releases/latest")!
    private static let releasePageURL = URL(string: "https://github.com/anasubaid19/fomo-doro/releases/latest")!
    private static let lastNotifiedKey = "lastNotifiedUpdate"
    private static let updateCategoryID = "UPDATE_AVAILABLE"

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Returns the latest release version if newer than the running app, else nil.
    static func check() async -> String? {
        guard let (data, _) = try? await URLSession.shared.data(from: releasesURL),
              let release = try? JSONDecoder().decode(GitHubRelease.self, from: data)
        else { return nil }
        let latest = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "v"))
        return isNewer(latest, than: currentVersion) ? latest : nil
    }

    /// First check after a short delay (lets notification permission settle), then daily.
    static func startBackgroundChecks() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            while !Task.isCancelled {
                await checkAndNotifyIfNeeded()
                try? await Task.sleep(nanoseconds: 43_200_000_000_000)
            }
        }
    }

    static func checkAndNotifyIfNeeded() async {
        guard Bundle.main.bundleIdentifier != nil else { return }
        guard let latest = await check() else { return }
        guard AppSettings.defaults.string(forKey: lastNotifiedKey) != latest else { return }
        AppSettings.defaults.set(latest, forKey: lastNotifiedKey)
        notify(version: latest)
    }

    private static func notify(version: String) {
        let center = UNUserNotificationCenter.current()
        let open = UNNotificationAction(
            identifier: NotificationDelegate.openActionID,
            title: "Open",
            options: .foreground
        )
        let category = UNNotificationCategory(
            identifier: updateCategoryID,
            actions: [open],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = "FomoDoro \(version) is available"
        content.body = "Download the update from GitHub Releases."
        content.categoryIdentifier = updateCategoryID
        center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    private static func isNewer(_ a: String, than b: String) -> Bool {
        let ca = parse(a), cb = parse(b)
        for i in 0..<3 where ca[i] != cb[i] { return ca[i] > cb[i] }
        return false
    }

    private static func parse(_ version: String) -> [Int] {
        let parts = version.split(separator: ".").compactMap { Int($0) }
        return (parts + [0, 0, 0]).prefix(3).map { $0 }
    }
}

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let openActionID = "OPEN_RELEASE"
    nonisolated(unsafe) static let shared = NotificationDelegate()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == Self.openActionID else { return }
        _ = await MainActor.run {
            NSWorkspace.shared.open(URL(string: "https://github.com/anasubaid19/fomo-doro/releases/latest")!)
        }
    }
}
