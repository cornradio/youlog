import SwiftUI

struct TagEditorView: View {
    @Binding var selectedTag: String?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tagManager = AppConstants.tagManager
    @State private var newTag = ""
    @State private var showingAddTag = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(tagManager.availableTags, id: \.self) { tag in
                        Button(action: {
                            if editMode == .inactive {
                                selectedTag = tagManager.isAllTag(tag) ? nil : tag
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(tag)
                                Spacer()
                                if (selectedTag == nil && tagManager.isAllTag(tag)) || selectedTag == tag {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let tag = tagManager.availableTags[index]
                            if !tagManager.isUntaggedTag(tag) {
                                tagManager.deleteTag(tag)
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        tagManager.availableTags.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .environment(\.editMode, $editMode)
                
                // 底部提示信息
                VStack(spacing: 8) {
                    Divider()
                    Text(NSLocalizedString("swipe_to_delete", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle(NSLocalizedString("select_tag", comment: ""))
            .navigationBarItems(
                leading: Button(NSLocalizedString("cancel", comment: "")) {
                    dismiss()
                }
                .foregroundColor(AppConstants.themeManager.currentTheme.color),
                trailing: HStack {
                    // EditButton()
                    Button(action: {
                        showingAddTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                }
            )
            .sheet(isPresented: $showingAddTag) {
                NavigationView {
                    Form {
                        TextField(NSLocalizedString("enter_new_tag", comment: ""), text: $newTag)
                    }
                    .navigationTitle(NSLocalizedString("add_tag", comment: ""))
                    .navigationBarItems(
                        leading: Button(NSLocalizedString("cancel", comment: "")) {
                            showingAddTag = false
                        }
                        .foregroundColor(AppConstants.themeManager.currentTheme.color),
                        trailing: Button(NSLocalizedString("add", comment: "")) {
                            if !newTag.isEmpty {
                                tagManager.addTag(newTag)
                                newTag = ""
                                showingAddTag = false
                            }
                        }
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                    )
                }
            }
        }
    }
}

