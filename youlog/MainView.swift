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
    @State private var showingSettings = false
    @State private var showingSystemCamera = false
    
    enum TimeRange {
        case day, week, month
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
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
    
    private var dateRangeText: String {
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        // Helper to check if two dates are same day
        func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
            calendar.isDate(date1, inSameDayAs: date2)
        }
        
        // Check "Today"
        if isSameDay(startDate, today) && isSameDay(endDate, today) {
            return "今天"
        }
        
        // Check "Recent 3 Days"
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: startOfToday),
           isSameDay(startDate, threeDaysAgo) && isSameDay(endDate, today) {
            return "近三天"
        }
        
        // Check "Recent 1 Week"
        if let oneWeekAgo = calendar.date(byAdding: .day, value: -6, to: startOfToday),
           isSameDay(startDate, oneWeekAgo) && isSameDay(endDate, today) {
            return "近一周"
        }
        
        // Check "Recent 1 Month"
        if let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: startOfToday),
           isSameDay(startDate, oneMonthAgo) && isSameDay(endDate, today) {
            return "近一个月"
        }
        
        // Check "All" (2025-01-01 to Today)
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        if let allStartDate = calendar.date(from: components),
           isSameDay(startDate, allStartDate) && isSameDay(endDate, today) {
            return "全部"
        }
        
        return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                //photocard place
                HStack(spacing: 0) {
                    if filteredItems.isEmpty {
                        EmptyStateView(
                            title: NSLocalizedString("no_photos_title", value: "无图片", comment: ""),
                            description: NSLocalizedString("no_photos_desc", value: "尝试更改日期或添加新照片", comment: "")
                        )
                    } else if isGridView {
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

            //底部空间
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider() // 顶部分割线
                    
                    HStack(spacing: 0) {
                        // 1. 日期筛选栏
                        Button(action: { showingDateFilter = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                Text(dateRangeText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        
                        // 2. tag 选择器
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
                            VStack(spacing: 4) {
                                Image(systemName: "tag")
                                    .font(.title2)
                                Text(selectedTag ?? tagManager.allTag)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        
                        // 3. 设置菜单按钮
                        Button(action: { showingSettings = true }) {
                            VStack(spacing: 4) {
                                Image(systemName: "gear")
                                    .font(.title2)
                                Text("设置")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        
                        // 4. 加号按钮 (放在最右侧)
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
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("添加")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                    }
                }
                .background(.ultraThinMaterial) // 整个底部栏使用毛玻璃背景
                .foregroundColor(AppConstants.themeManager.currentTheme.color)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(selectedTag: $selectedTag)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView { selectedImages in
                    // Batch processed images
                    var assetIdsToDelete: [String] = []
                    
                    for (imageData, assetId) in selectedImages {
                        addItem(imageData: imageData)
                        if let assetId = assetId {
                            assetIdsToDelete.append(assetId)
                        }
                    }
                    
                    // Batch delete
                    if !assetIdsToDelete.isEmpty {
                        deletePhotosFromLibrary(assetIds: assetIdsToDelete)
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
            .sheet(isPresented: $showingSettings) {
                SettingsView(isGridView: $isGridView, items: items, filteredItems: filteredItems)
            }
            .fullScreenCover(isPresented: $showingSystemCamera) {
                SystemCameraView { imageData in
                    if let imageData = imageData {
                        addItem(imageData: imageData)
                    }
                }
                .background(.black)
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
    
    private func deletePhotosFromLibrary(assetIds: [String]) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
        guard assets.count > 0 else { return }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assets)
        }) { success, error in
            if success {
                print("Successfully deleted original photos")
            } else if let error = error {
                print("Error deleting original photos: \(error.localizedDescription)")
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
