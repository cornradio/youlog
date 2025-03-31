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
                                selectedTag = tag == "全部" ? nil : tag
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(tag)
                                Spacer()
                                if (selectedTag == nil && tag == "全部") || selectedTag == tag {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let tag = tagManager.availableTags[index]
                            tagManager.deleteTag(tag)
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
                    Text("左滑删除，长按排序")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("选择标签")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: HStack {
                    EditButton()
                    Button(action: {
                        showingAddTag = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            )
            .sheet(isPresented: $showingAddTag) {
                NavigationView {
                    Form {
                        TextField("输入新标签", text: $newTag)
                    }
                    .navigationTitle("添加标签")
                    .navigationBarItems(
                        leading: Button("取消") {
                            showingAddTag = false
                        },
                        trailing: Button("添加") {
                            if !newTag.isEmpty {
                                tagManager.addTag(newTag)
                                newTag = ""
                                showingAddTag = false
                            }
                        }
                    )
                }
            }
        }
    }
}

