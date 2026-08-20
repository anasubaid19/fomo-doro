import AppKit
import SwiftUI
import SwiftData
import Combine

enum MenuBarLayoutPolicy {
    static func shouldReserveCountdownWidth(
        showsCountdown: Bool,
        hasActiveSession: Bool,
        isPopoverVisible: Bool
    ) -> Bool {
        showsCountdown && (hasActiveSession || isPopoverVisible)
    }
}

@MainActor
final class MenuBarController {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var store: TimerStore?
    private var reservedStatusItemLength: CGFloat = 0
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
        if let button = item.button {
            reservedStatusItemLength = Self.countdownLength(for: button)
        }

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

        NotificationCenter.default.publisher(for: NSPopover.didCloseNotification, object: pop)
            .sink { [weak self] _ in
                Task { @MainActor in self?.updateStatusItemLength() }
            }
            .store(in: &cancellables)

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

        updateStatusItemLength()
    }

    private func refreshButton() {
        guard let store else { return }
        statusItem?.button?.title = store.menuBarText
        statusItem?.button?.setAccessibilityLabel(store.voiceOverText)
        updateStatusItemLength()
    }

    private static func countdownLength(for button: NSButton) -> CGFloat {
        let originalTitle = button.title
        let candidates = ["🍅 120:00", "⏸ 120:00", "🍅 ✓"]
        let width = candidates.reduce(CGFloat.zero) { widest, title in
            button.title = title
            button.invalidateIntrinsicContentSize()
            return max(widest, button.intrinsicContentSize.width, button.cell?.cellSize.width ?? 0)
        }
        button.title = originalTitle
        button.invalidateIntrinsicContentSize()
        return ceil(width)
    }

    private func updateStatusItemLength(isPopoverVisible: Bool? = nil) {
        guard let statusItem, let store else { return }
        let shouldReserve = MenuBarLayoutPolicy.shouldReserveCountdownWidth(
            showsCountdown: AppSettings.showMenuBarCountdown,
            hasActiveSession: store.currentKind != nil,
            isPopoverVisible: isPopoverVisible ?? (popover?.isShown == true)
        )
        statusItem.length = shouldReserve && reservedStatusItemLength > 0
            ? reservedStatusItemLength
            : NSStatusItem.variableLength
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
        updateStatusItemLength(isPopoverVisible: true)
        button.window?.contentView?.layoutSubtreeIfNeeded()
        // An empty positioning rect tells AppKit to keep using the positioning
        // view's current bounds. Passing button.bounds snapshots its old width,
        // so the popover drifts off-center when the countdown expands the item.
        popover.show(relativeTo: .zero, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)
    }
}
