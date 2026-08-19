import AppKit
import XCTest
@testable import FomoDoroLegacy

final class LegacyPopoverLayoutTests: XCTestCase {
    @MainActor
    func testApplyPinsHostingControllerAndPopoverToFixedContentSize() {
        let viewController = NSViewController()
        viewController.view = NSView(frame: .zero)
        let popover = NSPopover()

        LegacyPopoverLayout.apply(to: popover, contentViewController: viewController)

        XCTAssertEqual(viewController.preferredContentSize, LegacyPopoverLayout.contentSize)
        XCTAssertEqual(viewController.view.frame.size, LegacyPopoverLayout.contentSize)
        XCTAssertEqual(popover.contentSize, LegacyPopoverLayout.contentSize)
    }

    @MainActor
    func testRestoreReappliesSizeAfterAppKitChangesIt() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 720, height: 1_302)

        LegacyPopoverLayout.restoreContentSize(of: popover)

        XCTAssertEqual(popover.contentSize, LegacyPopoverLayout.contentSize)
    }
}
