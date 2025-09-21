//
//  MainView.swift
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

struct MainView: View {
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
    @State private var showingLiquidGlassTest = false
    
    enum TimeRange {
        case day, week, month
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
    
    var filteredItems: [Item] {
        items.filter { item in
            let dateFilter = item.timestamp >= startDate && item.timestamp <= endDate
            let tagFilter: Bool
            
            if selectedTag == nil || tagManager.isAllTag(selectedTag ?? "") {
                // 显示所有图片
                tagFilter = true
            } else if tagManager.isUntaggedTag(selectedTag ?? "") {
                // 显示未分类图片（没有tag的图片）
                tagFilter = item.tag == nil
            } else {
                // 显示指定tag的图片
                tagFilter = item.tag == selectedTag
            }
            
            return dateFilter && tagFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                //photocard place
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
            // 顶部空间
            .safeAreaInset(edge: .top) {
                GlassEffectContainer() {
                HStack {
                        // 日期筛选栏和
                        Button(action: { showingDateFilter = true }) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))")
                            }
                            .glassMenu()
                        }
                        
                        Spacer()
                                                // 设置菜单按钮
                        Menu {
                            Button(action: { isGridView.toggle() }) {
                                Label(isGridView ? "列表视图" : "网格视图", systemImage: isGridView ? "square.fill.text.grid.1x2" : "square.grid.2x2")
                            }
                            
                            Divider()
                            
                            Button(action: { showingCompressionSettings = true }) {
                                Label("压缩设置", systemImage: "slider.horizontal.3")
                            }
                            
                            Button(action: { showingThemeSettings = true }) {
                                Label("主题", systemImage: "paintbrush")
                            }
                            
                            Divider()
                            
                            Button(action: { showingDataStats = true }) {
                                Label("数据统计", systemImage: "chart.bar")
                            }
                            
                            Button(action: { showingImageCleaner = true }) {
                                Label("图片清理", systemImage: "trash")
                            }
                            
                            Button(action: { showingNetworkTransfer = true }) {
                                Label("照片打包", systemImage: "externaldrive")
                            }
                            
                            if filteredItems.count > 1 {
                                Button(action: {
                                    currentPlaybackIndex = 0
                                    showingPlayback = true
                                }) {
                                    Label(NSLocalizedString("playback_mode", comment: ""), systemImage: "play.circle")
                                }
                            }
                            
                            Divider()
                            
                            // 仅在测试包名时显示开发菜单项
                            if Bundle.main.bundleIdentifier == "test.org.cornradio.youlog" {
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
                                
                                Button(action: {
                                    showingLiquidGlassTest = true
                                }) {
                                    Label("Liquid Glass 测试", systemImage: "sparkles")
                                }
                                
                                Divider()
                            }
                            
                            Button(action: { showingSupportDeveloper = true }) {
                                Label("支持", systemImage: "cup.and.saucer")
                            }
                            
                            Button(action: { showingHelp = true }) {
                                Label(NSLocalizedString("help", comment: ""), systemImage: "questionmark.circle")
                            }
                        } label: {
                            Image(systemName: "gear")
//                                .font(.system(size: 20, weight: .medium))
//                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
                                .glassMenu()
                        }
                        // 设置菜单按钮 over

                        // tag 选择器
                        Menu {
                            ForEach(tagManager.availableTags, id: \.self) { tag in
                                Button(action: {
                                    if tagManager.isAllTag(tag) {
                                        selectedTag = nil
                                    } else {
                                        selectedTag = tag
                                    }
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
                            .glassMenu()

                        }

                       
                        
                    }
                    .padding()
                }
                
            }
            //底部空间
            .safeAreaInset(edge: .bottom) {
                GlassEffectContainer(spacing: 60.0) {
                    HStack() {

                        // Spacer()
                        // 添加菜单按钮
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
                            
                            if !filteredItems.isEmpty {
                                Button(role: .destructive, action: { showingDeleteAllAlert = true }) {
                                    Label(NSLocalizedString("delete_all_photos", comment: ""), systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "plus")
                                  .glassCircleButton(tint: AppConstants.themeManager.currentTheme.color)
//                                .font(.system(size: 20, weight: .medium))
//                                .foregroundColor(AppConstants.themeManager.currentTheme.color)
//                                .frame(width: 56, height: 56)
//                                .clipShape(Circle())
//                                .glassEffect()
                        }
                        // + btn over
                        

                        
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
            .sheet(isPresented: $showingLiquidGlassTest) {
                LiquidGlassTestView()
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
    MainView()
        .modelContainer(for: Item.self, inMemory: true)
}


extension View {
    func glassCircleButton(diameter: CGFloat = 64, tint: Color = .white) -> some View {
        self
            .foregroundStyle(tint)
            .frame(width: diameter, height: diameter)
            .contentShape(Circle())
            .glassEffect(.regular.interactive())
            .clipShape(Circle())
    }

    func actionIcon(font: Font = .title2) -> some View {
        self
            .font(font)
            .contentTransition(.symbolEffect(.replace))
    }
    
    func glassMenu()-> some View {
        self
            .padding()
            .foregroundColor(AppConstants.themeManager.currentTheme.color)
            .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
            .cornerRadius(28)
            .glassEffect(.regular.interactive())
    }
}
