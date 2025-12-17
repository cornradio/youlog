import SwiftUI

struct PhotoCard3: View {
    let item: Item
    var allItems: [Item] = []
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingFullScreen = false
    @State private var showingSaveSuccess = false
    @State private var showingQuickActions = false
    @State private var showingNoteEditor = false
    @State private var editedNote: String = ""
    @State private var showingTagEditor = false
    @State private var selectedTag: String?
    @State private var currentImageIndex: Int = 0
    @State private var showingDatePicker = false
    @State private var selectedDate: Date = Date()
    
    init(item: Item, allItems: [Item] = []) {
        self.item = item
        self.allItems = allItems.isEmpty ? [item] : allItems
        _editedNote = State(initialValue: item.note ?? "")
        _selectedDate = State(initialValue: item.timestamp)
        _selectedTag = State(initialValue: item.tag)
    }
    
    private var itemImages: [UIImage] {
        allItems.compactMap { item in
            if let imageData = item.imageData {
                return UIImage(data: imageData)
            }
            return nil
        }
    }
    
    private var currentItemIndex: Int {
        allItems.firstIndex(where: { $0.id == item.id }) ?? 0
    }
    
    // 时间格式化器 - 显示完整日期时间
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 12) {
                // 1. 左侧缩略图
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentImageIndex = currentItemIndex
                            showingFullScreen = true
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    DispatchQueue.main.async {
                                        showingNoteEditor = true
                                    }
                                }
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                }
                
                // 2. 中间信息区域
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // 时间
                        Text(item.timestamp, formatter: fullDateFormatter)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Tag
                        if let tag = selectedTag {
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                                .cornerRadius(4)
                        }
                    }
                    
                    // 备注
                    Text(item.note?.isEmpty == false ? item.note! : "无备注")
                        .font(.body)
                        .foregroundColor(item.note?.isEmpty == false ? .primary : .secondary)
                        .lineLimit(1)
                }
                .contentShape(Rectangle()) // 让空白区域也可点击
                .onTapGesture {
                    // 点击文字区域也打开笔记编辑
                     showingNoteEditor = true
                }
                
                // 3. 右侧菜单按钮
                Menu {
                    if let imageData = item.imageData,
                       let uiImage = UIImage(data: imageData) {
                        MenuContent(
                            uiImage: uiImage,
                            item: item,
                            selectedTag: $selectedTag,
                            editedNote: $editedNote,
                            showingDeleteAlert: $showingDeleteAlert,
                            showingSaveSuccess: $showingSaveSuccess,
                            showingTagEditor: $showingTagEditor,
                            showingNoteEditor: $showingNoteEditor,
                            onEditTime: {
                                showingDatePicker = true
                            }
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            
            // MARK: - 弹窗逻辑 (与 Card2 保持一致)
            .alert(NSLocalizedString("delete_photo", comment: ""), isPresented: $showingDeleteAlert) {
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                    modelContext.delete(item)
                }
            } message: {
                Text(NSLocalizedString("delete_confirm_photo", comment: ""))
            }
            .alert(NSLocalizedString("save_success", comment: ""), isPresented: $showingSaveSuccess) {
                Button(NSLocalizedString("ok", comment: ""), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("saved_to_photos", comment: ""))
            }
            .navigationDestination(isPresented: $showingFullScreen) {
                ImageDetailView(images: itemImages, currentIndex: $currentImageIndex) { compressedImage, index in
                    if index < allItems.count {
                        let targetItem = allItems[index]
                        if let compressedData = compressedImage.jpegData(compressionQuality: 0.8) {
                            targetItem.imageData = compressedData
                        }
                    }
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
                        editedNote = item.note ?? ""
                    }
                    .onDisappear {
                        item.note = editedNote
                    }
            }
            .sheet(isPresented: $showingDatePicker) {
                // ... 日期选择器逻辑，可复用 ...
                NavigationView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                            Divider()
                            DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                        }
                        Spacer()
                        Text("修改后可能需要重新筛选找到照片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .navigationTitle("修改时间")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("取消") { showingDatePicker = false }
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("保存") {
                                item.timestamp = selectedDate
                                showingDatePicker = false
                            }
                        }
                    }
                }
                .onAppear { selectedDate = item.timestamp }
            }
        }
    }
}
