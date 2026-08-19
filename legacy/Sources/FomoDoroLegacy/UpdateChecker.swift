import Foundation
import Sparkle

/// Owns Sparkle's standard update flow for the lifetime of the application.
/// The legacy build uses a separate feed so macOS 12-13 only receives a
/// compatible FomoDoro Legacy package.
@MainActor
final class UpdateChecker {
    static let shared = UpdateChecker()

    private let controller: SPUStandardUpdaterController

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
