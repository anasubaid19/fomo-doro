import AppKit
import UniformTypeIdentifiers

@MainActor
protocol LegacySoundPanel: AnyObject {
    var allowedContentTypes: [UTType] { get set }
    var canChooseFiles: Bool { get set }
    var canChooseDirectories: Bool { get set }
    var allowsMultipleSelection: Bool { get set }
    var url: URL? { get }

    func runModal() -> NSApplication.ModalResponse
}

extension NSOpenPanel: LegacySoundPanel {}

@MainActor
enum LegacySoundFilePicker {
    static func chooseAudioFile(
        panelFactory: () -> any LegacySoundPanel = { NSOpenPanel() }
    ) -> URL? {
        let panel = panelFactory()
        panel.allowedContentTypes = [.audio]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
