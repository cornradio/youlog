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
                        ThumbnailView(item: item, isSelected: selectedItems.contains(item), isSelectionMode: isSelectionMode)
                            .onTapGesture {
                                if isSelectionMode {
                                    toggleSelection(for: item)
                                }
                            }
                            // 如果不是选择模式，NavigationLink 应该包裹整个缩略图。
                            // 但由于 NavigationLink 和 onTapGesture 混用可能冲突，
                            // 我们推荐：在非选择模式下，ThumbnailView 仅仅是展示，外层包裹 NavigationLink。
                            // 在选择模式下，点击触发 toggle。
                            .overlay {
                                if !isSelectionMode {
                                    NavigationLink(destination: ImageDetailWrapper(items: imageItems, initialItem: item)) {
                                        Color.clear // 透明覆盖层作为点击区域
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

struct ThumbnailView: View {
    let item: Item
    let isSelected: Bool
    let isSelectionMode: Bool
    
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                if let image = thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                                .scaleEffect(0.5)
                        }
                }
                
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .white)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .padding(4)
                }
            }
            .onAppear {
                loadThumbnail(targetSize: geo.size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private func loadThumbnail(targetSize: CGSize) {
        guard thumbnail == nil else { return }
        
        // 异步加载
        DispatchQueue.global(qos: .userInteractive).async {
            guard let imageData = item.imageData else { return }
            
            // 降采样逻辑
            let maxPixelSize = max(targetSize.width, targetSize.height) * UIScreen.main.scale
            
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
            ]
            
            guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self.thumbnail = uiImage
            }
        }
    }
}
