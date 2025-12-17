import SwiftUI

struct PhotoCard3: View {
    let item: Item
    var allItems: [Item] = []
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingFullScreen = false
    @State private var showingSaveSuccess = false
    @State private var showingNoteEditor = false
    @State private var editedNote: String = ""
    @State private var showingTagEditor = false
    @State private var selectedTag: String?
    @State private var currentImageIndex: Int = 0
    @State private var showingDatePicker = false
    @State private var selectedDate: Date = Date()
    @State private var decodedImage: UIImage? // Store decoded image
    
    init(item: Item, allItems: [Item] = []) {
        self.item = item
        self.allItems = allItems.isEmpty ? [item] : allItems
        _editedNote = State(initialValue: item.note ?? "")
        _selectedDate = State(initialValue: item.timestamp)
        _selectedTag = State(initialValue: item.tag)
    }
    
    private var currentItemIndex: Int {
        allItems.firstIndex(where: { $0.id == item.id }) ?? 0
    }
    
    var body: some View {
        // Removed nested NavigationStack to fix performance/freeze issues
        GeometryReader { geo in
            Group {
                if let uiImage = decodedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentImageIndex = currentItemIndex
                            showingFullScreen = true
                        }
                        .contextMenu {
                            // Long press context menu
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
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                        .task(id: item.id) {
                            await loadThumbnail(targetSize: CGSize(width: 150, height: 150))
                        }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        
        // MARK: - Popups
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
            ImageDetailView(items: allItems, currentIndex: $currentImageIndex) { compressedImage, index in
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
    
    private func loadThumbnail(targetSize: CGSize) async {
        guard let imageData = item.imageData else { return }
        
        let result = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: max(targetSize.width, targetSize.height) * 2 // Retain quality for retina
            ]
            
            guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }
            
            return UIImage(cgImage: cgImage)
        }.value
        
        if let image = result {
            await MainActor.run {
                self.decodedImage = image
            }
        }
    }
}
