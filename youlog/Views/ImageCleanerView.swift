//
//  ImageCleanerView.swift
//  youlog
//
//  Created by kasusa on 2025/9/21.
//


import SwiftUI
import SwiftData
import PhotosUI
import Photos
import AVKit
import AVFoundation
import PhotosUI
import SwiftUI

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