//
//  DataStatsView.swift
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
                        title: NSLocalizedString("未分类", comment: ""),
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