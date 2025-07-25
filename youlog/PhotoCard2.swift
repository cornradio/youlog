import SwiftUI

struct PhotoCard2: View {
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
            HStack(spacing: 0) {
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .bottom) {
                        }
                        .onTapGesture {
                            DispatchQueue.main.async {
                                currentImageIndex = currentItemIndex
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
                
                // 日期 时间
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        
                        var dateFormatter1: DateFormatter {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "MM/dd"
                            return formatter
                        }

                        Text(item.timestamp, formatter: dateFormatter1)
                            .font(.system(size: 18, weight: .bold)) // Custom font size
                            .foregroundColor(.secondary)

                        var dateFormatter2: DateFormatter {
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            return formatter
                        }

                        Text(item.timestamp, formatter: dateFormatter2)
                            .font(.system(size: 18)) // Custom font size
                            .foregroundColor(.primary)
                    }
                    .padding( 4)
                    // 星期几
                    var dayOfWeekFormatter: DateFormatter {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "EEEE" // Day of the week
                        return formatter
                    }
                    Text(item.timestamp, formatter: dayOfWeekFormatter)
                        .font(.body) // Custom font size
                        .foregroundColor(.primary)
                        .padding( 4)
                    
                    //tag
                    Menu {
                        ForEach(AppConstants.tagManager.availableTags, id: \ .self) { tag in
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
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(2)
                            .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }.padding( 4)
                    //note
                    if let note = item.note, !note.isEmpty {
                        VStack {
                            ZStack {
                                Text(note)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineLimit(8)
                                    .padding( 4)
                                
                                Spacer()
                            }
                            .padding( 4)
                            .onTapGesture {
                                DispatchQueue.main.async {
                                    showingNoteEditor = true
                                }
                            }
                        }
                    }
                    
                    Spacer()

                    HStack{
                        
                        Menu {
                            if let imageData = item.imageData,
                               let uiImage = UIImage(data: imageData) {
                                MenuContent(uiImage: uiImage, item: item,
                                          selectedTag: $selectedTag,
                                          editedNote: $editedNote, showingDeleteAlert: $showingDeleteAlert, showingSaveSuccess: $showingSaveSuccess, showingTagEditor: $showingTagEditor, showingNoteEditor: $showingNoteEditor)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                            Text(NSLocalizedString("more", comment: ""))
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)	
                                
                        }
                        .padding( 4)
                        Spacer()
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
            .navigationDestination(isPresented: $showingFullScreen) {
                ImageDetailView(images: itemImages, currentIndex: $currentImageIndex)
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
        }
    }
    
} 
