import SwiftUI

// MARK: - 图片显示组件
struct PhotoImageView: View {
    let imageData: Data?
    let note: String?
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onLongPress: () -> Void
    let onNoteTap: () -> Void
    
    var body: some View {
        if let imageData = imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .bottom) {
                    if let note = note, !note.isEmpty {
                        VStack {
                            Spacer()
                            ZStack {
                                Text(note)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .onTapGesture {
                                onNoteTap()
                            }
                        }
                    }
                }
                .onTapGesture {
                    onTap()
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            onLongPress()
                        }
                )
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
    }
}

// MARK: - 标签按钮组件
struct TagButton: View {
    let item: Item
    @Binding var selectedTag: String?
    
    var body: some View {
        Menu {
            ForEach(AppConstants.tagManager.availableTags, id: \.self) { tag in
                Button(action: {
                    selectedTag = AppConstants.tagManager.isAllTag(tag) ? nil : tag
                    item.tag = selectedTag
                }) {
                    HStack {
                        Text(tag)
                        if (item.tag == nil && AppConstants.tagManager.isAllTag(tag)) || item.tag == tag {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        }
                    }
                }
            }
        } label: {
            Text(item.tag ?? NSLocalizedString("all", comment: ""))
                .font(.caption)
                .foregroundColor(.primary)
                .padding(2)
                .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - 时间显示组件
struct TimeDisplay: View {
    let timestamp: Date
    let onTap: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }
    
    var body: some View {
        HStack {
            Text(timestamp, formatter: timeFormatter)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text(timestamp, formatter: dateFormatter)
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 照片卡片主视图
struct PhotoCard: View {
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
        _selectedTag = State(initialValue: item.tag)
        _selectedDate = State(initialValue: item.timestamp)
    }
    
    private var currentItemIndex: Int {
        allItems.firstIndex(where: { $0.id == item.id }) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                PhotoImageView(
                    imageData: item.imageData,
                    note: item.note,
                    onTap: { 
                        currentImageIndex = currentItemIndex
                        showingFullScreen = true
                    },
                    onDoubleTap: { },
                    onLongPress: { 
                        showingNoteEditor = true 
                    },
                    onNoteTap: { 
                        showingNoteEditor = true 
                    }
                )
                
                HStack {
                    TimeDisplay(timestamp: item.timestamp) {
                        showingDatePicker = true
                    }
                    
                    TagButton(item: item, selectedTag: $selectedTag)
                    
                    Spacer();
                    
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
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppConstants.themeManager.currentTheme.color)
                    }
                }
                .padding(.vertical, 8)
            }
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
            .navigationDestination(isPresented: $showingFullScreen) {
                ImageDetailView(items: allItems, currentIndex: $currentImageIndex) { compressedImage, index in
                    if index < allItems.count {
                        let targetItem = allItems[index]
                        let settings = CompressionSettings.shared
                        if let compressedData = compressedImage.jpegData(compressionQuality: settings.compressionQuality) {
                            targetItem.imageData = compressedData
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
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
                .onAppear {
                    selectedDate = item.timestamp
                }
            }
        }
    }
}
