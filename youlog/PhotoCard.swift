import SwiftUI

struct PhotoCard: View {
    let item: Item
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingFullScreen = false
    @State private var showingSaveSuccess = false
    @State private var showingQuickActions = false
    @State private var showingNoteEditor = false
    @State private var editedNote: String = ""
    @State private var showingTagEditor = false
    @State private var selectedTag: String?
    
    init(item: Item) {
        self.item = item
        _editedNote = State(initialValue: item.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .bottom) {
                                //在图片上显示笔记
                                if let note = item.note, !note.isEmpty {
                                    VStack {
                                        Spacer()
                                        
                                        
                                        ZStack {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.black.opacity(0.5))
                                        }.onTapGesture {
                                            DispatchQueue.main.async {
                                                showingNoteEditor = true
                                            }
                                        }
                                    }

                                }
                            }
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    showingFullScreen = true
                                }
                            }
                            .simultaneousGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        DispatchQueue.main.async {
                                            showingQuickActions = true
                                        }
                                    }
                            )
                        // 菜单
                        .contextMenu {
                            MenuContent(uiImage: uiImage, item: item, selectedTag: $selectedTag, editedNote: $editedNote, showingDeleteAlert: $showingDeleteAlert, showingSaveSuccess: $showingSaveSuccess, showingTagEditor: $showingTagEditor, showingNoteEditor: $showingNoteEditor)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                    }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack{
                                //time
                                var dateFormatter1: DateFormatter {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "MM/dd"
                                    return formatter
                                }
                                Text(item.timestamp, formatter: dateFormatter1)
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                                var dateFormatter2: DateFormatter {
                                    let formatter = DateFormatter()
                                    formatter.dateFormat = "HH:mm"
                                    return formatter
                                }
                                Text(item.timestamp, formatter: dateFormatter2)
                                    .font(.caption)
                                    .foregroundColor(.primary)

                                //tag
                                Button(action: {
                                    selectedTag = item.tag
                                    showingTagEditor = true
                                }) {
                                    Text(item.tag ?? "全部")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(2)
                                        .background(Color.blue.opacity(0.5))
                                        .cornerRadius(4)
                                }
                                //button for more actions
                                Menu {
                                    if let imageData = item.imageData,
                                       let uiImage = UIImage(data: imageData) {
                                        MenuContent(uiImage: uiImage, item: item, 
                                        selectedTag: $selectedTag,
                                         editedNote: $editedNote, showingDeleteAlert: $showingDeleteAlert, showingSaveSuccess: $showingSaveSuccess, showingTagEditor: $showingTagEditor, showingNoteEditor: $showingNoteEditor)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundColor(.blue)
                                }

                            }

                        }
                        .padding(.horizontal, 4)
                        
                    }
            .alert("删除照片", isPresented: $showingDeleteAlert) {
                    Button("取消", role: .cancel) { }
                    Button("删除", role: .destructive) {
                        modelContext.delete(item)
                    }
                } message: {
                    Text("确定要删除这张照片吗？")
                }
                .alert("保存成功", isPresented: $showingSaveSuccess) {
                    Button("确定", role: .cancel) { }
                } message: {
                    Text("照片已保存到相册")
                }
                .navigationDestination(isPresented: $showingFullScreen) {
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        ImageDetailView(image: uiImage)
                    }
                }
                .sheet(isPresented: $showingTagEditor) {
                    TagEditorView(selectedTag: $selectedTag)
                        .onDisappear {
                            item.tag = selectedTag
                        }
                }
                .sheet(isPresented: $showingNoteEditor) {
                    NoteEditorView(note: $editedNote)
                        .onAppear {
                            editedNote = item.note ?? "没有吗？"
                        }
                        .onDisappear {
                            item.note = editedNote
                        }
                }
            }
        }
    }
    
    // 共享的菜单内容视图
    struct MenuContent: View {
        let uiImage: UIImage
        let item: Item
        @Binding var selectedTag: String?
        @Binding var editedNote: String
        @Binding var showingDeleteAlert: Bool
        @Binding var showingSaveSuccess: Bool
        @Binding var showingTagEditor: Bool
        @Binding var showingNoteEditor: Bool
        
        var body: some View {
            Button(action: {
                DispatchQueue.global(qos: .background).async {
                    UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                    DispatchQueue.main.async {
                        showingSaveSuccess = true
                    }
                }
            }) {
                Label("保存到相册", systemImage: "square.and.arrow.down")
            }

            Button(action: {
                selectedTag = item.tag
                showingTagEditor = true
            }) {
                Label("编辑标签", systemImage: "tag")
            }

            Button(action: {
                editedNote = item.note ?? ""
                showingNoteEditor = true
            }) {
                Label("编辑笔记", systemImage: "pencil")
            }

            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("删除照片", systemImage: "trash")
            }
        }
    }
    
    struct TagEditorView: View {
        @Binding var selectedTag: String?
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                List {
                    ForEach(AppConstants.availableTags, id: \.self) { tag in
                        Button(action: {
                            selectedTag = tag == "全部" ? nil : tag
                            dismiss()
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
                }
                .navigationTitle("选择标签")
                .navigationBarItems(trailing: Button("取消") {
                    dismiss()
                })
            }
        }
    }

