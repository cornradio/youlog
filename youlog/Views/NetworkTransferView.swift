//
//  NetworkTransferView.swift
//  youlog
//  用于图片打包保存到文件
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
                    
                    Text("将照片保存到文件App，我的iPhone，youlog文件夹中")
                }
                .padding()
                .background(AppConstants.themeManager.currentTheme.color.opacity(0.1))
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
