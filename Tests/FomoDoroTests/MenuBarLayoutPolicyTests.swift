import XCTest
@testable import FomoDoro

final class MenuBarLayoutPolicyTests: XCTestCase {
    func testReservesCountdownWidthBeforePopoverIsShown() {
        XCTAssertTrue(
            MenuBarLayoutPolicy.shouldReserveCountdownWidth(
                showsCountdown: true,
                hasActiveSession: false,
                isPopoverVisible: true
            )
        )
    }

    func testKeepsCountdownWidthWhileSessionIsActive() {
        XCTAssertTrue(
            MenuBarLayoutPolicy.shouldReserveCountdownWidth(
                showsCountdown: true,
                hasActiveSession: true,
                isPopoverVisible: false
            )
        )
    }

    func testReturnsToVariableWidthOnlyWhenIdleAndClosed() {
        XCTAssertFalse(
            MenuBarLayoutPolicy.shouldReserveCountdownWidth(
                showsCountdown: true,
                hasActiveSession: false,
                isPopoverVisible: false
            )
        )
    }

    func testDoesNotReserveSpaceWhenCountdownIsHidden() {
        XCTAssertFalse(
            MenuBarLayoutPolicy.shouldReserveCountdownWidth(
                showsCountdown: false,
                hasActiveSession: true,
                isPopoverVisible: true
            )
        )
    }
}
