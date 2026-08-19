import Foundation
import Sparkle

/// Owns Sparkle's standard update flow for the lifetime of the application.
/// Sparkle presents the update, downloads it, verifies its EdDSA signature,
/// installs it atomically, and relaunches FomoDoro when the user confirms.
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
