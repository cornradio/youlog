import SwiftUI
import SwiftData

struct AllImagesView: View {
    let items: [Item]
    @Environment(\.modelContext) private var modelContext
    @State private var isSelectionMode = false
    @State private var selectedItems: Set<Item> = []
    @State private var showDeleteConfirmation = false
    
    // Filter items with images and sort by date descending
    var imageItems: [Item] {
        items.filter { $0.imageData != nil }
             .sorted { $0.timestamp > $1.timestamp }
    }
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            if imageItems.isEmpty {
                ContentUnavailableView("没有图片", systemImage: "photo.on.rectangle.angled")
                    .padding(.top, 50)
            } else {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(imageItems) { item in
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            let imageContent = GeometryReader { geo in
                                ZStack(alignment: .bottomTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: geo.size.width, height: geo.size.width)
                                        .clipped()
                                    
                                    if isSelectionMode {
                                        Image(systemName: selectedItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(selectedItems.contains(item) ? .blue : .white)
                                            .background(Circle().fill(Color.black.opacity(0.4)))
                                            .padding(6)
                                    }
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)

                            if isSelectionMode {
                                imageContent
                                    .onTapGesture {
                                        toggleSelection(for: item)
                                    }
                            } else {
                                NavigationLink(destination: ImageDetailWrapper(items: imageItems, initialItem: item)) {
                                    imageContent
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(isSelectionMode ? "已选择 \(selectedItems.count) 张" : "所有图片")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isSelectionMode ? "取消" : "选择") {
                    withAnimation {
                        isSelectionMode.toggle()
                        selectedItems.removeAll()
                    }
                }
            }
            
            if isSelectionMode {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Spacer()
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .disabled(selectedItems.isEmpty)
                    }
                }
            }
        }
        .confirmationDialog("确认删除", isPresented: $showDeleteConfirmation) {
            Button("删除 \(selectedItems.count) 张图片", role: .destructive) {
                deleteSelectedItems()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复。")
        }
    }
    
    private func toggleSelection(for item: Item) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    private func deleteSelectedItems() {
        withAnimation {
            for item in selectedItems {
                modelContext.delete(item)
            }
            selectedItems.removeAll()
            isSelectionMode = false
        }
    }
}

struct ImageDetailWrapper: View {
    let items: [Item]
    let initialItem: Item
    @State private var currentIndex: Int = 0
    
    init(items: [Item], initialItem: Item) {
        self.items = items
        self.initialItem = initialItem
        // Calculate initial index
        if let index = items.firstIndex(where: { $0.id == initialItem.id }) {
            _currentIndex = State(initialValue: index)
        }
    }
    
    var body: some View {
        ImageDetailView(items: items, currentIndex: $currentIndex)
    }
}
