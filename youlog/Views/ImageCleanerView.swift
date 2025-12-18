import SwiftUI
import SwiftData

struct ImageCleanerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var tagManager = AppConstants.tagManager
    
    let items: [Item]
    
    // 筛选状态
    @State private var selectedFilters: Set<FilterMode> = []
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var largeImageThresholdMB: Double = 5.0
    @State private var selectedTag: String?
    
    @State private var showingDeleteConfirmation = false
    @State private var showingSimpleDeleteConfirmation = false
    @State private var itemsToDelete: [Item] = []
    @State private var totalSize: Int = 0
    
    enum FilterMode: String, CaseIterable {
        case dateRange = "按日期范围"
        case largeImages = "按图片大小"
        case byTag = "按图片标签"
        
        var description: String {
            switch self {
            case .dateRange: return "指定时间段内的图片"
            case .largeImages: return "超过指定文件大小的图片"
            case .byTag: return "属于特定分类标签的图片"
            }
        }
        
        var icon: String {
            switch self {
            case .dateRange: return "calendar"
            case .largeImages: return "arrow.up.left.and.arrow.down.right"
            case .byTag: return "tag"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("清理范围"), footer: Text(selectedFilters.isEmpty ? "💡 未开启任何筛选时，将清理所有包含图片的记录" : "💡 已开启组合筛选，仅清理符合所有选中条件的记录")) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        HStack {
                            Label(mode.rawValue, systemImage: mode.icon)
                                .font(.headline)
                            Spacer()
                            if selectedFilters.contains(mode) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppConstants.themeManager.currentTheme.color)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedFilters.contains(mode) {
                                selectedFilters.remove(mode)
                            } else {
                                selectedFilters.insert(mode)
                            }
                        }
                    }
                }
                
                if selectedFilters.contains(.dateRange) {
                    Section("日期范围") {
                        DatePicker("开始日期", selection: $startDate, displayedComponents: .date)
                        DatePicker("结束日期", selection: $endDate, displayedComponents: .date)
                    }
                }
                
                if selectedFilters.contains(.largeImages) {
                    Section("大小阈值") {
                        HStack {
                            Slider(value: $largeImageThresholdMB, in: 0.1...20, step: 0.1)
                            Text(String(format: "%.1f MB", largeImageThresholdMB))
                                .frame(width: 70, alignment: .trailing)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                
                if selectedFilters.contains(.byTag) {
                    Section("标签筛选") {
                        Picker("点击选择标签", selection: $selectedTag) {
                            Text("全部").tag(String?.none)
                            ForEach(tagManager.availableTags.filter { !tagManager.isAllTag($0) }, id: \.self) { tag in
                                Text(tag).tag(String?.some(tag))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("预览结果") {
                    let previewItems = getItemsToDelete()
                    let previewSize = previewItems.compactMap { $0.imageData?.count }.reduce(0, +)
                    
                    VStack(spacing: 12) {
                        StatRow(title: "命中记录数", value: "\(previewItems.count)")
                        StatRow(title: "预计释放空间", value: formatFileSize(previewSize))
                    }
                    .padding(.vertical, 8)
                    
                    if !previewItems.isEmpty {
                        Button(action: {
                            itemsToDelete = previewItems
                            totalSize = previewSize
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "eye")
                                Text("查看并逐条清理")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(AppConstants.themeManager.currentTheme.color)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        itemsToDelete = getItemsToDelete()
                        totalSize = itemsToDelete.compactMap { $0.imageData?.count }.reduce(0, +)
                        showingSimpleDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("一键清理符合条件的图片")
                        }
                        .frame(maxWidth: .infinity)
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
            .confirmationDialog("确认清理", isPresented: $showingSimpleDeleteConfirmation) {
                Button("清理 \(itemsToDelete.count) 张照片", role: .destructive) {
                    deleteItems(itemsToDelete)
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("将永久删除 \(itemsToDelete.count) 个记录中的图片数据，释放 \(formatFileSize(totalSize)) 空间。此操作不可撤销。")
            }
            .onAppear {
                if selectedTag == nil {
                    // 默认选择第一个有效标签或未分类
                    selectedTag = tagManager.availableTags.first { !tagManager.isAllTag($0) }
                }
            }
        }
    }
    
    private func getItemsToDelete() -> [Item] {
        var result = items.filter { $0.imageData != nil }
        
        // 组合筛选逻辑 (AND)
        if selectedFilters.contains(.dateRange) {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: startDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
            
            result = result.filter { $0.timestamp >= start && $0.timestamp <= end }
        }
        
        if selectedFilters.contains(.largeImages) {
            let thresholdBytes = Int(largeImageThresholdMB * 1024 * 1024)
            result = result.filter { ($0.imageData?.count ?? 0) >= thresholdBytes }
        }
        
        if selectedFilters.contains(.byTag), let tag = selectedTag {
            if tagManager.isUntaggedTag(tag) {
                result = result.filter { $0.tag == nil }
            } else {
                result = result.filter { $0.tag == tag }
            }
        }
        
        return result
    }
    
    private func deleteItems(_ itemsToDelete: [Item]) {
        withAnimation {
            for item in itemsToDelete {
                // 如果只想清理图片保留记录，可以将 imageData 设为 nil
                // 但根据之前的逻辑是 delete 整个 item
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}