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
            .navigationTitle("记录你的变化")
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
            .alert("删除全部照片", isPresented: $showingDeleteAllAlert) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    deleteAllItems()
                }
            } message: {
                Text("确定要删除所有照片吗？此操作无法撤销。")
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
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

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("如何拍出合适的照片")
                            .font(.title)
                            .bold()
                        
                        Text("1. 位置选择")
                            .font(.headline)
                        Text("• 选择固定的拍摄位置，保持每天在同一位置拍摄\n• 确保背景简洁，避免杂乱\n• 选择有特色的背景，如窗户、墙面等\n• 保持拍摄距离一致")
                        
                        Text("2. 动作姿势")
                            .font(.headline)
                        Text("• 保持自然放松的姿势\n• 可以尝试不同的动作，但建议每天保持相似\n• 注意保持身体姿态的一致性\n• 可以加入一些手势或道具增加趣味性")
                        
                        Text("3. 光线控制")
                            .font(.headline)
                        Text("• 选择光线充足的时间段\n• 避免强烈的直射光\n• 注意光线的方向，建议使用侧光或柔和的自然光\n• 保持每天拍摄时间相近，确保光线条件一致")
                    }
                    
                    Group {
                        Text("4. 拍摄技巧")
                            .font(.headline)
                        Text("• 使用手机支架保持稳定\n• 开启网格线辅助构图\n• 注意保持画面水平\n• 可以尝试不同的拍摄角度")
                        
                        Text("5. 注意事项")
                            .font(.headline)
                        Text("• 确保拍摄环境整洁\n• 注意服装搭配的协调性\n• 保持心情愉悦，展现真实的自己\n• 记录下每天的变化和进步")
                    }
                }
                .padding()
            }
            .navigationBarItems(trailing: Button("完成") {
                dismiss()
            })
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

struct TagButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.3))
                .cornerRadius(8)
//                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
