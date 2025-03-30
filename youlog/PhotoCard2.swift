import SwiftUI

struct PhotoCard2: View {
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
    @State private var isDeleting = false
    @State private var showingDeleteAnimation = false
    
    init(item: Item) {
        self.item = item
        _editedNote = State(initialValue: item.note ?? "")
    }
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                if showingDeleteAnimation, let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                    DeleteAnimationView(image: uiImage, isAnimating: $isDeleting) {
                        modelContext.delete(item)
                    }
                } else if let imageData = item.imageData,
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
                    Button(action: {
                        selectedTag = item.tag
                        showingTagEditor = true
                    }) {
                        Text(item.tag ?? "全部")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(2)
                            .background(.indigo.opacity(0.1))
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
                                .foregroundColor(.blue)
                            Text("更多")
                                .foregroundColor(.blue)	
                                
                        }
                        .padding( 4)
                        Spacer()
                    }

                    
                }
                .padding(.horizontal, 4)
            }
            .alert("删除照片", isPresented: $showingDeleteAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    showingDeleteAnimation = true
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
                        editedNote = item.note ?? ""
                    }
                    .onDisappear {
                        item.note = editedNote
                    }
            }
        }
    }
    
} 
