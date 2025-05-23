import SwiftUI

// 图片显示组件
struct PhotoImageView: View {
    let imageData: Data?
    let note: String?
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onNoteTap: () -> Void
    
    var body: some View {
        if let imageData = imageData,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
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

// 标签按钮组件
struct TagButton: View {
    let tag: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag ?? NSLocalizedString("all", comment: ""))
                .font(.caption)
                .foregroundColor(.primary)
                .padding(2)
                .background(.indigo.opacity(0.1))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// 时间显示组件
struct TimeDisplay: View {
    let timestamp: Date
    
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
    }
}

// 主视图
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
    @State private var isMenuEnabled = true
    
    init(item: Item, allItems: [Item] = []) {
        self.item = item
        self.allItems = allItems.isEmpty ? [item] : allItems
        _editedNote = State(initialValue: item.note ?? "")
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
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                PhotoImageView(
                    imageData: item.imageData,
                    note: item.note,
                    onTap: { 
                        currentImageIndex = currentItemIndex
                        showingFullScreen = true
                    },
                    onLongPress: { showingQuickActions = true },
                    onNoteTap: { showingNoteEditor = true }
                )
                .contextMenu {
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
                            showingNoteEditor: $showingNoteEditor
                        )
                    }
                }
                
                HStack {
                    TimeDisplay(timestamp: item.timestamp)
                    
                    TagButton(tag: item.tag) {
                        selectedTag = item.tag
                        showingTagEditor = true
                    }
                    
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
                                showingNoteEditor: $showingNoteEditor
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 4)
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
                ImageDetailView(images: itemImages, currentIndex: $currentImageIndex)
            }
        }
    }
}

   
