import SwiftUI
import SwiftData
import AppKit

@main
struct FomoDoroApp: App {
    @StateObject private var store: TimerStore
    private let container: ModelContainer

    @MainActor
    init() {
        Self.ensureSingleInstance()
        AppSettings.registerDefaults()
        let config = ModelConfiguration(url: Self.storeURL)
        let c = try! ModelContainer(for: TaskItem.self, FocusSession.self, configurations: config)
        container = c
        _store = StateObject(wrappedValue: TimerStore(modelContext: c.mainContext))
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    // ponytail: single-instance by process name so the dev binary and the .app bundle
    // (different bundle ids) still detect each other; exit before any icon is drawn.
    static func ensureSingleInstance() {
        let others = NSWorkspace.shared.runningApplications.filter {
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
                && $0.executableURL?.lastPathComponent == "FomoDoro"
        }
        if !others.isEmpty { exit(0) }
    }

    // ponytail: explicit store URL so dev (`swift run`) and the .app bundle share one
    // isolated store instead of colliding with a default-location store.
    static var storeURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FomoDoro", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("store.sqlite")
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .modelContainer(container)
                .environmentObject(store)
        } label: {
            Text(store.menuBarText)
                .accessibilityLabel(store.voiceOverText)
        }
        .menuBarExtraStyle(.window)
    }
}
