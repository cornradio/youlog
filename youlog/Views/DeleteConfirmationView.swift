//
//  DeleteConfirmationView.swift
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