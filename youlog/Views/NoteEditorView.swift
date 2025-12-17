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
            ZStack {
                
                VStack {
                    TextEditor(text: $tempNote)
                        .padding()
                        .background(Color.clear)
                        .scrollContentBackground(.hidden)
                }
                .background(.ultraThinMaterial) // 毛玻璃背景
            }
            .navigationTitle(NSLocalizedString("edit_note", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        // Clear Button
                        Button(action: {
                            tempNote = ""
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title2)
                                Text(NSLocalizedString("clear", comment: ""))
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        
                        // Cancel Button
                        Button(action: {
                            dismiss()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                Text(NSLocalizedString("cancel", comment: ""))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                        
                        // Done Button
                        Button(action: {
                            note = tempNote
                            dismiss()
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.title2)
                                Text(NSLocalizedString("done", comment: ""))
                                    .font(.caption)
                            }
                            .foregroundColor(AppConstants.themeManager.currentTheme.color)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
            }
        }
    }
}
