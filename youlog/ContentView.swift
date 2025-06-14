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
                        PhotoCard(item: item, allItems: items)
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
                        PhotoCard2(item: item, allItems: items)
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
    @StateObject private var tagManager = AppConstants.tagManager
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
    @State private var showingDevMenu = false
    @State private var isContinuousCapture = false
    @State private var captureCount = 0
    @State private var showingDataStats = false
    @State private var captureTimer: Timer?
    
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
            let tagFilter = selectedTag == nil || tagManager.isAllTag(selectedTag ?? "") || item.tag == selectedTag
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
                        ForEach(tagManager.availableTags, id: \.self) { tag in
                            Button(action: {
                                selectedTag = tagManager.isAllTag(tag) ? nil : tag
                            }) {
                                HStack {
                                    Text(tag)
                                    if (selectedTag == nil && tagManager.isAllTag(tag)) || selectedTag == tag {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button(action: {
                            showingTagEditor = true
                        }) {
                            Label(NSLocalizedString("edit_tags", comment: ""), systemImage: "pencil")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "tag")
                            Text(selectedTag ?? tagManager.allTag)
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
            .navigationTitle(selectedTag == nil ? NSLocalizedString("record_all", comment: "") : String(format: NSLocalizedString("record_tag", comment: ""), selectedTag ?? ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingDevMenu = true }) {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { isGridView.toggle() }) {
                            Image(systemName: isGridView ? "square.grid.2x2" : "square.fill.text.grid.1x2")
                                .foregroundColor(.blue)
                        }
                        
                        Menu {
                            Button(action: { showingCamera = true }) {
                                Label(NSLocalizedString("take_photo", comment: ""), systemImage: "camera")
                            }

                            Button(action: { showingImagePicker = true }) {
                                Label(NSLocalizedString("select_from_album", comment: ""), systemImage: "photo.on.rectangle")
                            }

                            if filteredItems.count > 1 {
                                Button(action: { 
                                    currentPlaybackIndex = 0
                                    showingPlayback = true 
                                }) {
                                    Label(NSLocalizedString("playback_mode", comment: ""), systemImage: "play.circle")
                                }
                            }
                            
                            if !filteredItems.isEmpty {
                                Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                                    Label(NSLocalizedString("delete_all_photos", comment: ""), systemImage: "trash")
                                }
                            }
                            
                            Button(action: { showingHelp = true }) {
                                Label(NSLocalizedString("help", comment: ""), systemImage: "questionmark.circle")
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
            .confirmationDialog(NSLocalizedString("delete_all_photos", comment: ""), isPresented: $showingDeleteAllAlert) {
                Button(NSLocalizedString("delete", comment: ""), role: .destructive) {
                    deleteAllItems()
                }
                Button(NSLocalizedString("cancel", comment: ""), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("delete_confirm_all", comment: ""))
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingTagEditor) {
                TagEditorView(selectedTag: $selectedTag)
            }
            .confirmationDialog("开发功能", isPresented: $showingDevMenu) {
                Button(isContinuousCapture ? "停止连续拍照" : "开始连续拍照") {
                    isContinuousCapture.toggle()
                    if isContinuousCapture {
                        startContinuousCapture()
                    } else {
                        stopContinuousCapture()
                    }
                }
                
                Button("数据统计") {
                    showingDataStats = true
                }
                
                Button("取消", role: .cancel) { }
            }
            .sheet(isPresented: $showingDataStats) {
                DataStatsView(items: items)
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
    
    private func startContinuousCapture() {
        captureCount = 0
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let newItem = Item(timestamp: Date(), 
                             imageData: generateTestImage(),
                             tag: selectedTag)
            modelContext.insert(newItem)
            captureCount += 1
        }
    }
    
    private func stopContinuousCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
    }
    
    private func generateTestImage() -> Data? {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let text = "Test Image \(captureCount)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 30),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: (size.height - textSize.height) / 2,
                                width: textSize.width,
                                height: textSize.height)
            text.draw(in: textRect, withAttributes: attributes)
        }
        return image.jpegData(compressionQuality: 0.8)
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

// 数据统计视图
struct DataStatsView: View {
    let items: [Item]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("基本统计") {
                    StatRow(title: "总记录数", value: "\(items.count)")
                    StatRow(title: "有图片的记录", value: "\(items.filter { $0.imageData != nil }.count)")
                    StatRow(title: "有笔记的记录", value: "\(items.filter { $0.note != nil }.count)")
                    StatRow(title: "有位置的记录", value: "\(items.filter { $0.location != nil }.count)")
                }
                
                Section("存储统计") {
                    let totalImageSize = items.compactMap { $0.imageData?.count }.reduce(0, +)
                    StatRow(title: "图片总大小", value: formatFileSize(totalImageSize))
                    StatRow(title: "平均图片大小", value: formatFileSize(totalImageSize / max(items.count, 1)))
                }
                
                Section("时间统计") {
                    if let firstItem = items.first {
                        StatRow(title: "最早记录", value: formatDate(firstItem.timestamp))
                    }
                    if let lastItem = items.last {
                        StatRow(title: "最新记录", value: formatDate(lastItem.timestamp))
                    }
                }
            }
            .navigationTitle("数据统计")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
