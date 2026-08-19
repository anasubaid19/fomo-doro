import Foundation

enum LegacyLaunchAtLogin {
    private static let label = "dev.anasubaid.fomodoro.legacy.login"

    private static var agentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: agentURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            disable()
        }
    }

    private static func enable() throws {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension == "app" else {
            throw LaunchError.requiresAppBundle
        }

        let directory = agentURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/usr/bin/open", bundleURL.path],
            "RunAtLoad": true
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: agentURL, options: .atomic)
        runLaunchctl(["load", agentURL.path])
    }

    private static func disable() {
        guard isEnabled else { return }
        runLaunchctl(["unload", agentURL.path])
        try? FileManager.default.removeItem(at: agentURL)
    }

    private static func runLaunchctl(_ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        try? process.run()
        process.waitUntilExit()
    }

    private enum LaunchError: LocalizedError {
        case requiresAppBundle

        var errorDescription: String? {
            "Launch at login is available after installing the app in Applications."
        }
    }
}
