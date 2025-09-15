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
                
                // 右下角的圆形对勾按钮
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            note = tempNote
                            dismiss()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(AppConstants.themeManager.currentTheme.color)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
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
                    }.foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("done", comment: "")) {
                        note = tempNote
                        dismiss()
                    }
                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                }
            }
        }
    }
}
