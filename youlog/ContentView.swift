//
//  ContentView.swift
//  youlog
//
//  Created by kasusa on 2025/3/28.
//

import SwiftUI
import SwiftData
import PhotosUI
import Photos
import AVKit
import AVFoundation

import PhotosUI
import SwiftUI

struct PhotoTimelineView: View {
    let items: [Item]
    @Binding var selectedDate: Date
    let scrollToItem: (Item) -> Void
    @State private var isFirstAppear = true
    
    // 定义自适应网格列
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        PhotoCard(item: item)
                            .id(item.id)
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = item.timestamp
                                    scrollToItem(item)
                                }
                            }
                    }
                }
                .padding()
            }
            .onAppear {
                if isFirstAppear {
                    proxy.scrollTo(items.first?.id, anchor: .top)
                    isFirstAppear = false
                }
            }
        }
    }
}

struct PhotoTimelineView2: View {
    let items: [Item]
    @Binding var selectedDate: Date
    let scrollToItem: (Item) -> Void
    @State private var isFirstAppear = true
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        PhotoCard2(item: item)
                            .id(item.id)
                            .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = item.timestamp
                                    scrollToItem(item)
                                }
                            }
                    }
                }
                .padding()
            }
            .onAppear {
                if isFirstAppear {
                    proxy.scrollTo(items.first?.id, anchor: .top)
                    isFirstAppear = false
                }
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @State private var showingCamera = false
    @State private var selectedTimeRange: TimeRange = .day
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var editingItem: Item?
    @State private var showingPlayback = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showingImagePicker = false
    @State private var currentPlaybackIndex = 0
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.endOfDay(for: Date())
    @State private var showingDateFilter = false
    @State private var showingDeleteAllAlert = false
    @State private var showingHelp = false
    @State private var selectedTag: String? = nil
    @State private var showingTagEditor = false
    @AppStorage("isGridView") private var isGridView = true  // 使用 @AppStorage 替代 @State
    
    enum TimeRange {
        case day, week, month
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
    
    var filteredItems: [Item] {
        items.filter { item in
            let dateFilter = item.timestamp >= startDate && item.timestamp <= endDate
            let tagFilter = selectedTag == nil || selectedTag == "全部" || item.tag == selectedTag
            return dateFilter && tagFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 日期筛选栏和 Tag 选择器
                HStack {
                    Button(action: { showingDateFilter = true }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(28)
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(AppConstants.availableTags, id: \.self) { tag in
                            Button(action: {
                                selectedTag = tag == "全部" ? nil : tag
                            }) {
                                HStack {
                                    Text(tag)
                                    if (selectedTag == nil && tag == "全部") || selectedTag == tag {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingTagEditor = true
                        }) {
                            Label("编辑标签", systemImage: "pencil")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag")
                            Text(selectedTag ?? "全部")
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cornerRadius(8)
                    }
                    
                    Button(action: { showingCamera = true }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .padding()
                
                HStack(spacing: 0) {
                    if isGridView {
                        PhotoTimelineView(
                            items: filteredItems,
                            selectedDate: $selectedDate,
                            scrollToItem: scrollToItem
                        )
                    } else {
                        PhotoTimelineView2(
                            items: filteredItems,
                            selectedDate: $selectedDate,
                            scrollToItem: scrollToItem
                        )
                    }
                }
            }
            .navigationTitle(selectedTag == nil ? "记录你的全部" : "记录你的\(selectedTag ?? "")")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { isGridView.toggle() }) {
                            Image(systemName: isGridView ? "square.grid.2x2" : "square.fill.text.grid.1x2")
                                .foregroundColor(.blue)
                        }
                        
                        Menu {
                            Button(action: { showingCamera = true }) {
                                Label("拍照", systemImage: "camera")
                            }

                            Button(action: { showingImagePicker = true }) {
                                Label("从相册选择", systemImage: "photo.on.rectangle")
                            }

                            if filteredItems.count > 1 {
                                Button(action: { 
                                    currentPlaybackIndex = 0
                                    showingPlayback = true 
                                }) {
                                    Label("播放模式", systemImage: "play.circle")
                                }
                            }
                            
                            if !filteredItems.isEmpty {
                                Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                                    Label("删除全部照片", systemImage: "trash")
                                }
                            }
                            
                            Button(action: { showingHelp = true }) {
                                Label("帮助", systemImage: "questionmark.circle")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedTag: $selectedTag)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { imageData in
                    if let imageData = imageData {
                        addItem(imageData: imageData)
                    }
                }
            }
            .fullScreenCover(isPresented: $showingPlayback) {
                PlaybackView(items: filteredItems, currentIndex: $currentPlaybackIndex)
            }
            .sheet(isPresented: $showingDateFilter) {
                DateFilterView(startDate: $startDate, endDate: $endDate)
            }
            .confirmationDialog("删除全部照片", isPresented: $showingDeleteAllAlert) {
                Button("删除", role: .destructive) {
                    deleteAllItems()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("确定要删除所有照片吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingTagEditor) {
                TagEditorView(selectedTag: $selectedTag)
            }
        }
    }
    
    private func addItem(imageData: Data? = nil) {
        withAnimation {
            let newItem = Item(timestamp: Date(), imageData: imageData, tag: selectedTag)
            modelContext.insert(newItem)
        }
    }
    
    private func deleteAllItems() {
        withAnimation {
            for item in filteredItems {
                modelContext.delete(item)
            }
        }
    }
    
    private func scrollToItem(_ item: Item) {
        withAnimation {
            scrollProxy?.scrollTo(item.id, anchor: .center)
        }
    }
}

extension Calendar {
    func startOfDay(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day], from: date)
        return self.date(from: components) ?? date
    }
    
    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date)) ?? date
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    let onImageDataSelected: (Data?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    parent.onImageDataSelected(imageData)
                } else {
                    parent.onImageDataSelected(nil)
                }
            } else {
                parent.onImageDataSelected(nil)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


// 添加图片缩放扩展
extension UIImage {
    func scaled(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
