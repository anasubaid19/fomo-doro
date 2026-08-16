import SwiftUI

struct NotesView: View {
    // ponytail: single scratchpad in UserDefaults; multi-note → SwiftData NoteItem
    @AppStorage("scratchNote") private var text = ""

    var body: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .font(.body)
                .padding(6)
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Quick note — jot something down…")
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .allowsHitTesting(false)
                    }
                }
            HStack {
                Spacer()
                Text("Autosaved")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 10)
                    .padding(.bottom, 4)
            }
        }
    }
}
