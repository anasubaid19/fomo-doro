import AppKit
import SwiftUI
import SwiftData
import Combine

@MainActor
final class MenuBarController {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var store: TimerStore?
    private var cancellables: Set<AnyCancellable> = []

    private init() {}

    func setup(store: TimerStore, container: ModelContainer) {
        self.store = store

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.title = store.menuBarText
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.target = self
            button.action = #selector(togglePopover)
            button.setAccessibilityLabel(store.voiceOverText)
        }
        statusItem = item

        let hosting = NSHostingController(
            rootView: ContentView()
                .modelContainer(container)
                .environmentObject(store)
        )
        hosting.sizingOptions = .preferredContentSize

        let pop = NSPopover()
        pop.behavior = .transient
        pop.contentViewController = hosting
        popover = pop

        store.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in self?.refreshButton() }
            }
            .store(in: &cancellables)

        store.$justCompletedFocus
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] completed in
                Task { @MainActor in self?.handleCompletion(completed) }
            }
            .store(in: &cancellables)
    }

    private func refreshButton() {
        guard let store else { return }
        statusItem?.button?.title = store.menuBarText
        statusItem?.button?.setAccessibilityLabel(store.voiceOverText)
    }

    private func handleCompletion(_ completed: Bool) {
        refreshButton()
        guard completed,
              AppSettings.autoOpenPopoverOnCompletion,
              let popover, !popover.isShown
        else { return }
        showPopover()
    }

    @objc private func togglePopover() {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let popover, let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }
}
