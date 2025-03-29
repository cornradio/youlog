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
            .navigationTitle("编辑笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("清空") {
                        tempNote = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        note = tempNote
                        dismiss()
                    }
                }
            }
        }
    }
}
