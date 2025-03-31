import SwiftUI

struct NoteEditorView: View {
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss
    @State private var tempNote: String

    init(note: Binding<String>) {
        self._note = note
        self._tempNote = State(initialValue: note.wrappedValue)
    }

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $tempNote)
                    .padding()
                    .background(Color(.systemBackground))
            }
            .navigationTitle(NSLocalizedString("edit_note", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("cancel", comment: "")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(NSLocalizedString("clear", comment: "")) {
                        tempNote = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("done", comment: "")) {
                        note = tempNote
                        dismiss()
                    }
                }
            }
        }
    }
}
