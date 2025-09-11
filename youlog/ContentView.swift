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
    @StateObject private var themeManager = AppConstants.themeManager
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
    @State private var showingImageCleaner = false
    @State private var showingSystemCamera = false
    @State private var showingNetworkTransfer = false
    @State private var localServerURL: String = ""
    @State private var isServerRunning = false
    @State private var showingSupportDeveloper = false
    @State private var showingThemeSettings = false
    @State private var showingCompressionSettings = false
    
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
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
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
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        if CompressionSettings.shared.defaultUseSystemCamera {
                            showingSystemCamera = true
                        } else {
                            showingCamera = true
                        }
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppConstants.themeManager.currentTheme.color)
                            .cornerRadius(8)
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                if CompressionSettings.shared.defaultUseSystemCamera {
                                    showingCamera = true
                                } else {
                                    showingSystemCamera = true
                                }
                            }
                    )
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
                        // 仅在测试包名时显示开发菜单
                        if Bundle.main.bundleIdentifier == "test.org.cornradio.youlog" {
                            Menu {
                                Button(action: {
                                    isContinuousCapture.toggle()
                                    if isContinuousCapture {
                                        startContinuousCapture()
                                    } else {
                                        stopContinuousCapture()
                                    }
                                }) {
                                    Label(isContinuousCapture ? "停止连续拍照" : "连续拍照测试", systemImage: "camera.badge.clock")
                                }
                                                    } label: {
                            Image(systemName: "hammer")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        }
                        }
                        
                        Button(action: { isGridView.toggle() }) {
                            Image(systemName: isGridView ? "square.grid.2x2" : "square.fill.text.grid.1x2")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                        }
                        
                        Menu {
                            Button(action: { showingCamera = true }) {
                                Label(NSLocalizedString("take_photo", comment: ""), systemImage: "camera")
                            }

                            Button(action: { showingSystemCamera = true }) {
                                Label("拍照（系统相机）", systemImage: "camera.aperture")
                            }

                            Button(action: { showingImagePicker = true }) {
                                Label(NSLocalizedString("select_from_album", comment: ""), systemImage: "photo.on.rectangle")
                            }
                            
                            Divider()
                            
                            Button(action: { showingCompressionSettings = true }) {
                                Label("压缩设置", systemImage: "slider.horizontal.3")
                            }

                            if !filteredItems.isEmpty {
                                Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                                    Label(NSLocalizedString("delete_all_photos", comment: ""), systemImage: "trash")
                                }
                            }
                            Divider()
                            
                            if filteredItems.count > 1 {
                                Button(action: { 
                                    currentPlaybackIndex = 0
                                    showingPlayback = true 
                                }) {
                                    Label(NSLocalizedString("playback_mode", comment: ""), systemImage: "play.circle")
                                }
                            }

                            
                            Button(action: { showingDataStats = true }) {
                                Label("数据统计", systemImage: "chart.bar")
                            }
                            
                            Button(action: { showingImageCleaner = true }) {
                                Label("图片清理", systemImage: "trash")
                            }
                            
                            Button(action: { showingNetworkTransfer = true }) {
                                Label("照片打包", systemImage: "externaldrive")
                            }
                            
                            Divider()
                                                        

                            
                            Button(action: { showingSupportDeveloper = true }) {
                                Label("支持", systemImage: "cup.and.saucer")
                            }
                            
                            Button(action: { showingHelp = true }) {
                                Label(NSLocalizedString("help", comment: ""), systemImage: "questionmark.circle")
                            }
                            
                            Button(action: { showingThemeSettings = true }) {
                                Label("主题", systemImage: "paintbrush")
                            }


                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
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
                DateFilterView(startDate: $startDate, endDate: $endDate, items: items)
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
                Button(isContinuousCapture ? "停止连续拍照" : "开始连续拍照（生成测试图片）") {
                    isContinuousCapture.toggle()
                    if isContinuousCapture {
                        startContinuousCapture()
                    } else {
                        stopContinuousCapture()
                    }
                }
                
                Button("取消", role: .cancel) { }
            }
            .sheet(isPresented: $showingDataStats) {
                DataStatsView(items: items)
            }
            .sheet(isPresented: $showingImageCleaner) {
                ImageCleanerView(items: items)
            }
            .sheet(isPresented: $showingNetworkTransfer) {
                NetworkTransferView(items: items)
            }
            .sheet(isPresented: $showingSystemCamera) {
                SystemCameraView { imageData in
                    if let imageData = imageData {
                        addItem(imageData: imageData)
                    }
                }
                .background(.black)
            }
            .sheet(isPresented: $showingSupportDeveloper) {
                SupportDeveloperView()
            }
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showingCompressionSettings) {
                CompressionSettingsView()
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
        // 使用与iPhone相机相同的尺寸比例 (4:3)
        let screenSize = UIScreen.main.bounds.size
        let imageWidth = screenSize.width * 3 // 3倍屏幕宽度以获得高分辨率
        let imageHeight = imageWidth * 4 / 3 // 4:3比例
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            // 根据captureCount选择不同的颜色
            let colors: [UIColor] = [
                .systemBlue,      // 蓝色
                .systemPurple,    // 紫色
                .systemYellow,    // 黄色
                .systemGreen,     // 绿色
                .systemOrange,    // 橙色
                .systemRed,       // 红色
                .systemPink,      // 粉色
                .systemIndigo,    // 靛蓝色
                .systemTeal,      // 青色
                .systemMint       // 薄荷色
            ]
            
            let colorIndex = captureCount % colors.count
            let backgroundColor = colors[colorIndex]
            
            // 填充背景色
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 添加渐变效果
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = CGRect(origin: .zero, size: size)
            gradientLayer.colors = [
                backgroundColor.cgColor,
                backgroundColor.withAlphaComponent(0.7).cgColor,
                backgroundColor.withAlphaComponent(0.9).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            
            // 绘制渐变
            if let gradientImage = gradientLayer.renderImage() {
                gradientImage.draw(in: CGRect(origin: .zero, size: size))
            }
            
            // 添加文字
            let text = "Test Image \(captureCount + 1)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size.width * 0.05), // 响应式字体大小
                .foregroundColor: UIColor.white,
                .strokeColor: UIColor.black,
                .strokeWidth: -2.0
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: (size.height - textSize.height) / 2,
                                width: textSize.width,
                                height: textSize.height)
            text.draw(in: textRect, withAttributes: attributes)
            
            // 添加时间戳
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            let timeText = dateFormatter.string(from: Date())
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.03),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let timeSize = timeText.size(withAttributes: timeAttributes)
            let timeRect = CGRect(x: 20,
                                y: size.height - timeSize.height - 20,
                                width: timeSize.width,
                                height: timeSize.height)
            timeText.draw(in: timeRect, withAttributes: timeAttributes)
        }
        return image.jpegData(compressionQuality: 0.9)
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

// 添加CAGradientLayer扩展，用于渲染渐变图像
extension CAGradientLayer {
    func renderImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
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
    @StateObject private var tagManager = AppConstants.tagManager
    
    var body: some View {
        NavigationView {
            List {
                Section("基本统计") {
                    StatRow(title: "图片总数", value: "\(items.count)")
                    StatRow(title: "有笔记的图片数", value: "\(items.filter { $0.note != nil }.count)")
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
                
                Section("标签统计") {
                    // 按标签统计图片数量（排除"全部"标签）
                    ForEach(tagManager.availableTags.filter { !tagManager.isAllTag($0) }, id: \.self) { tag in
                        let tagItems = items.filter { item in
                            return item.tag == tag
                        }
                        
                        if !tagItems.isEmpty {
                            let tagImageSize = tagItems.compactMap { $0.imageData?.count }.reduce(0, +)
                            StatRow(
                                title: tag,
                                value: "\(tagItems.count) 张 (\(formatFileSize(tagImageSize)))"
                            )
                        }
                    }
                    
                    // 未分类图片统计
                    let untaggedItems = items.filter { $0.tag == nil }
                    if !untaggedItems.isEmpty {
                        let untaggedImageSize = untaggedItems.compactMap { $0.imageData?.count }.reduce(0, +)
                        StatRow(
                            title: "未分类",
                            value: "\(untaggedItems.count) 张 (\(formatFileSize(untaggedImageSize)))"
                        )
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

// 图片清理视图
struct ImageCleanerView: View {
    let items: [Item]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCleanMode: CleanMode = .all
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingDeleteConfirmation = false
    @State private var showingSimpleDeleteConfirmation = false
    @State private var itemsToDelete: [Item] = []
    @State private var totalSize: Int = 0
    @State private var largeImageThresholdMB: Double = 5 // 默认5MB
    
    enum CleanMode: String, CaseIterable {
        case all = "所有图片"
        case dateRange = "按日期范围"
        case largeImages = "大图片 (>1MB)"
        
        var description: String {
            switch self {
            case .all:
                return "删除所有包含图片的记录"
            case .dateRange:
                return "删除指定日期范围内的图片记录"
            case .largeImages:
                return "删除图片大小超过指定阈值的记录"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section("清理模式") {
                    ForEach(CleanMode.allCases, id: \.self) { mode in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedCleanMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCleanMode = mode
                        }
                    }
                }
                
                if selectedCleanMode == .dateRange {
                    Section("日期范围") {
                        DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    }
                }
                
                if selectedCleanMode == .largeImages {
                    Section("大小阈值") {
                        HStack {
                            Slider(value: $largeImageThresholdMB, in: 0.1...10, step: 0.1) {
                                Text("阈值")
                            }
                            Text(String(format: "%.1fMB", largeImageThresholdMB))
                                .frame(width: 60, alignment: .trailing)
                        }
                        Text("只会删除大于此大小的图片")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("预览") {
                    let previewItems = getItemsToDelete()
                    let previewSize = previewItems.compactMap { $0.imageData?.count }.reduce(0, +)
                    
                    StatRow(title: "将删除的记录数", value: "\(previewItems.count)")
                    StatRow(title: "将释放的存储空间", value: formatFileSize(previewSize))
                    
                    if !previewItems.isEmpty {
                        Button("预览要删除的记录") {
                            itemsToDelete = previewItems
                            totalSize = previewSize
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                    }
                }
                
                Section {
                    Button("开始清理", role: .destructive) {
                        itemsToDelete = getItemsToDelete()
                        totalSize = itemsToDelete.compactMap { $0.imageData?.count }.reduce(0, +)
                        showingSimpleDeleteConfirmation = true
                    }
                    .disabled(getItemsToDelete().isEmpty)
                }
            }
            .navigationTitle("图片清理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDeleteConfirmation) {
                DeleteConfirmationView(
                    itemsToDelete: itemsToDelete,
                    totalSize: totalSize,
                    onDelete: {
                        deleteItems(itemsToDelete)
                        dismiss()
                    }
                )
            }
            .confirmationDialog("确认删除", isPresented: $showingSimpleDeleteConfirmation) {
                Button("删除 \(itemsToDelete.count) 个记录", role: .destructive) {
                    deleteItems(itemsToDelete)
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("将删除 \(itemsToDelete.count) 个记录，释放 \(formatFileSize(totalSize)) 存储空间。此操作不可撤销。")
            }
        }
    }
    
    private func getItemsToDelete() -> [Item] {
        switch selectedCleanMode {
        case .all:
            return items.filter { $0.imageData != nil }
        case .dateRange:
            return items.filter { item in
                item.imageData != nil && 
                item.timestamp >= startDate && 
                item.timestamp <= endDate
            }
        case .largeImages:
            let thresholdBytes = Int(largeImageThresholdMB * 1024 * 1024)
            return items.filter { item in
                if let imageData = item.imageData {
                    return imageData.count > thresholdBytes
                }
                return false
            }
        }
    }
    
    private func deleteItems(_ itemsToDelete: [Item]) {
        withAnimation {
            for item in itemsToDelete {
                modelContext.delete(item)
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - 删除确认视图
struct DeleteConfirmationView: View {
    let itemsToDelete: [Item]
    let totalSize: Int
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var images: [UIImage] {
        itemsToDelete.compactMap { item in
            if let imageData = item.imageData {
                return UIImage(data: imageData)
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 统计信息
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("将删除 \(itemsToDelete.count) 个记录")
                                .font(.headline)
                            Text("将释放 \(formatFileSize(totalSize)) 存储空间")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                }
                
                // 图片预览 - 九宫格布局
                if !images.isEmpty {
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(Array(itemsToDelete.enumerated()), id: \.element.id) { index, item in
                                if let imageData = item.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    VStack(spacing: 4) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                        
                                        Text(item.timestamp, style: .date)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("没有可预览的图片")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 300)
                }
                
                Spacer()
            }
            .navigationTitle("图片预览")
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
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// 系统相机视图
struct SystemCameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImageDataSelected: (Data?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: SystemCameraView
        
        init(_ parent: SystemCameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let settings = CompressionSettings.shared
                var finalImage = image
                
                // 如果开启了自动压缩，则进行压缩处理
                if settings.autoCompressSystemCamera {
                    finalImage = compressImage(image) ?? image
                }
                
                if let imageData = finalImage.jpegData(compressionQuality: 0.8) {
                    parent.onImageDataSelected(imageData)
                } else {
                    parent.onImageDataSelected(nil)
                }
            } else {
                parent.onImageDataSelected(nil)
            }
            parent.dismiss()
        }
        
        private func compressImage(_ image: UIImage) -> UIImage? {
            let settings = CompressionSettings.shared
            let targetWidth: CGFloat = settings.targetWidth
            let compressionQuality: CGFloat = settings.compressionQuality
            
            let originalSize = image.size
            
            var newSize: CGSize
            if originalSize.width > targetWidth {
                let ratio = targetWidth / originalSize.width
                newSize = CGSize(
                    width: targetWidth,
                    height: originalSize.height * ratio
                )
            } else {
                newSize = originalSize
            }
            
            // 使用 UIGraphicsImageRenderer 替代旧的方法
            let format = UIGraphicsImageRendererFormat()
            format.opaque = true
            format.scale = image.scale
            
            let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
            let resizedImage = renderer.image { context in
                // 填充黑色背景
                UIColor.black.setFill()
                context.fill(CGRect(origin: .zero, size: newSize))
                
                // 设置高质量插值
                context.cgContext.interpolationQuality = .high
                
                // 绘制图片
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            // 应用质量压缩
            guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality),
                  let compressedImage = UIImage(data: compressedData) else {
                return nil
            }
            
            // 裁切右边和下面1px
            guard let cgImage = compressedImage.cgImage else { return compressedImage }
            
            let cropRect = CGRect(
                x: 0,
                y: 0,
                width: max(1, cgImage.width - 1),
                height: max(1, cgImage.height - 1)
            )
            
            if let croppedCGImage = cgImage.cropping(to: cropRect) {
                return UIImage(cgImage: croppedCGImage, scale: compressedImage.scale, orientation: compressedImage.imageOrientation)
            }
            
            return compressedImage
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// 局域网传输视图
struct NetworkTransferView: View {
    let items: [Item]
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 状态显示
                VStack(spacing: 10) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 50))
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                    
                    Text("照片打包")
                        .font(.headline)
                        .foregroundColor(AppConstants.themeManager.currentTheme.color)
                }
                .padding()
                
                // 统计信息
                VStack(spacing: 8) {
                    let imageItems = items.filter { $0.imageData != nil }
                    let totalSize = imageItems.compactMap { $0.imageData?.count }.reduce(0, +)
                    
                    StatRow(title: "照片数量", value: "\(imageItems.count)")
                    StatRow(title: "总大小", value: formatFileSize(totalSize))
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // 说明文字
                VStack(spacing: 8) {
                    Text("📦 打包说明")
                        .font(.headline)
                    
                    Text("• 将照片保存到文件夹（文件App-我的iPhone-youlog）")
                    Text("• 您可以直接在文件App中访问和分享照片")
                    Text("• 也可以在文件App中压缩打包，然后备份到其他地方")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // 生成压缩包按钮
                Button(action: {
                    generateZipFile()
                }) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "archivebox.fill")
                        }
                        Text(isGenerating ? "正在打包..." : "打包照片")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isGenerating ? Color.gray : Color.blue)
                    .cornerRadius(12)
                }
                .disabled(items.filter { $0.imageData != nil }.isEmpty || isGenerating)
            }
            .padding()
            .navigationTitle("照片打包")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showingAlert) {
                Button("确定") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func generateZipFile() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let imageItems = items.filter { $0.imageData != nil }
            guard !imageItems.isEmpty else {
                DispatchQueue.main.async {
                    isGenerating = false
                    alertMessage = "没有找到照片"
                    showingAlert = true
                }
                return
            }
            
            // 创建Documents目录下的照片文件夹
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            let folderName = "photos_\(timestamp)"
            let photosFolder = documentsPath.appendingPathComponent(folderName)
            
            do {
                // 创建文件夹
                try FileManager.default.createDirectory(at: photosFolder, withIntermediateDirectories: true, attributes: nil)
                
                // 保存所有图片到文件夹
                for (index, item) in imageItems.enumerated() {
                    guard let imageData = item.imageData else { continue }
                    
                    let photoDateFormatter = DateFormatter()
                    photoDateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                    let photoTimestamp = photoDateFormatter.string(from: item.timestamp)
                    let photoFileName = "photo_\(photoTimestamp)_\(index + 1).jpg"
                    let photoURL = photosFolder.appendingPathComponent(photoFileName)
                    
                    try imageData.write(to: photoURL)
                }
                
                DispatchQueue.main.async {
                    isGenerating = false
                    
                    // 显示成功消息
                    alertMessage = "照片已保存到文件夹：\(folderName)\n\n您可以在文件App中找到此文件夹：\n文件App → 我的iPhone → youlog → \(folderName)"
                    showingAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    isGenerating = false
                    alertMessage = "保存文件失败: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

struct SupportDeveloperView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .frame(width: 60, height: 40)
                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                Text("Youlog 是免费 App，如果觉得这个软件很棒，欢迎用钱支持我！")
                    .multilineTextAlignment(.center)
                    .font(.title3)
                    .padding(.horizontal)
                // 收款码图片（请替换为您的二维码图片）
                Image("donate_qr")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
                    .shadow(radius: 8)
                    .padding(.bottom, 8)
                
                Text("也欢迎在 App Store 下您的好评！\n 以及把 App 分享给更多朋友！")
                Button(action: openAppStoreReview) {
                    Label("去 App Store 写好评", systemImage: "star.bubble.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppConstants.themeManager.currentTheme.color)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                Spacer()
            }
            .navigationTitle("支持开发者")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
           
        }
    }
    // 替换为您的App Store ID
    private let appStoreID = "6743986266"
    private func openAppStoreReview() {
        let urlStr = "https://apps.apple.com/app/id\(appStoreID)?action=write-review"
        if let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        }
    }
}
