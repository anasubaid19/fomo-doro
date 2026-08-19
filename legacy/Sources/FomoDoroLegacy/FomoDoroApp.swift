import SwiftUI
import AppKit
import UserNotifications

@main
struct FomoDoroLegacyApp: App {
    @StateObject private var store: TimerStore
    @StateObject private var dataStore: LegacyDataStore

    @MainActor
    init() {
        Self.ensureSingleInstance()
        AppSettings.registerDefaults()
        let dataStore = LegacyDataStore()
        _dataStore = StateObject(wrappedValue: dataStore)
        _store = StateObject(wrappedValue: TimerStore(dataStore: dataStore))
        NSApplication.shared.setActivationPolicy(.accessory)
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        UpdateChecker.startBackgroundChecks()
        // ponytail: defer notification permission until after launch — requesting it during
        // App.init crashed CI binaries (pre-macOS-26 SDK) on macOS 26.
        Task { @MainActor [store] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            store.requestNotificationPermission()
        }
        MenuBarController.shared.setup(store: store, dataStore: dataStore)
    }

    // ponytail: single-instance by process name so the dev binary and the .app bundle
    // (different bundle ids) still detect each other; exit before any icon is drawn.
    static func ensureSingleInstance() {
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
                && $0.executableURL?.lastPathComponent == "FomoDoroLegacy"
        }
        if !others.isEmpty { exit(0) }
    }

    var body: some Scene {
        Settings { EmptyView() }
    }
}
