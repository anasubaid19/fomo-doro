import AppKit
import UniformTypeIdentifiers
import XCTest
@testable import FomoDoroLegacy

final class LegacySoundFilePickerTests: XCTestCase {
    @MainActor
    func testCancellationCreatesAFreshPanelOnEveryAttempt() {
        var creationCount = 0

        let first = LegacySoundFilePicker.chooseAudioFile {
            creationCount += 1
            return StubSoundPanel(response: .cancel)
        }
        let second = LegacySoundFilePicker.chooseAudioFile {
            creationCount += 1
            return StubSoundPanel(response: .cancel)
        }

        XCTAssertNil(first)
        XCTAssertNil(second)
        XCTAssertEqual(creationCount, 2)
    }

    @MainActor
    func testSuccessfulSelectionReturnsURLAndConfiguresAudioOnly() {
        let expectedURL = URL(fileURLWithPath: "/tmp/completion.aiff")
        let panel = StubSoundPanel(response: .OK, url: expectedURL)

        let selectedURL = LegacySoundFilePicker.chooseAudioFile { panel }

        XCTAssertEqual(selectedURL, expectedURL)
        XCTAssertEqual(panel.allowedContentTypes, [.audio])
        XCTAssertTrue(panel.canChooseFiles)
        XCTAssertFalse(panel.canChooseDirectories)
        XCTAssertFalse(panel.allowsMultipleSelection)
    }
}

@MainActor
private final class StubSoundPanel: LegacySoundPanel {
    var allowedContentTypes: [UTType] = []
    var canChooseFiles = false
    var canChooseDirectories = true
    var allowsMultipleSelection = true
    let url: URL?

    private let response: NSApplication.ModalResponse

    init(response: NSApplication.ModalResponse, url: URL? = nil) {
        self.response = response
        self.url = url
    }

    func runModal() -> NSApplication.ModalResponse {
        response
    }
}
