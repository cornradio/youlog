//
//  SettingsView.swift
//  youlog
//
//  Created by kasusa on 2025/3/28.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var tagManager = AppConstants.tagManager
    @ObservedObject var themeManager = AppConstants.themeManager
    
    // Bindings from MainView
    @Binding var viewMode: Int
    
    // Data
    var items: [Item]
    var filteredItems: [Item]
    
    // State for sub-views
    @State private var showingCompressionSettings = false
    @State private var showingThemeSettings = false
    @State private var showingDataStats = false
    @State private var showingImageCleaner = false
    @State private var showingNetworkTransfer = false
    @State private var showingSupportDeveloper = false
    @State private var showingHelp = false
    @State private var showingLiquidGlassTest = false
    @State private var showingPlayback = false
    @State private var currentPlaybackIndex = 0
    
    // Developer Mode State
    @State private var isContinuousCapture = false
    @State private var captureCount = 0
    @State private var captureTimer: Timer?
    @State private var showingDevActionConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: { viewMode = 0 }) {
                        HStack {
                            Label("网格视图", systemImage: "square.grid.2x2")
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewMode == 0 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.currentTheme.color)
                            }
                        }
                    }
                    
                    Button(action: { viewMode = 1 }) {
                        HStack {
                            Label("大图视图", systemImage: "rectangle.portrait")
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewMode == 1 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.currentTheme.color)
                            }
                        }
                    }

                    Button(action: { viewMode = 2 }) {
                        HStack {
                            Label("列表视图", systemImage: "list.bullet")
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewMode == 2 {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(themeManager.currentTheme.color)
                            }
                        }
                    }
                } header: {
                    Text("View Mode")
                }
                
                Section {
                    Button(action: { showingThemeSettings = true }) {
                        Label("主题", systemImage: "paintbrush")
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Appearance")
                }
                
                Section {
                    Button(action: { showingCompressionSettings = true }) {
                        Label("压缩设置", systemImage: "slider.horizontal.3")
                            .foregroundStyle(.primary)
                    }
                    
                    Button(action: { showingDataStats = true }) {
                        Label("数据统计", systemImage: "chart.bar")
                            .foregroundStyle(.primary)
                    }
                    
                    Button(action: { showingImageCleaner = true }) {
                        Label("图片清理", systemImage: "trash")
                            .foregroundStyle(.primary)
                    }
                    
                    Button(action: { showingNetworkTransfer = true }) {
                        Label("照片打包", systemImage: "externaldrive")
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Data & Storage")
                }
                
                Section {
                    if filteredItems.count > 1 {
                        Button(action: {
                            currentPlaybackIndex = 0
                            showingPlayback = true
                        }) {
                            Label(NSLocalizedString("playback_mode", comment: ""), systemImage: "play.circle")
                                .foregroundStyle(.primary)
                        }
                    } else {
                        Label(NSLocalizedString("playback_mode", comment: ""), systemImage: "play.circle")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Tools")
                } footer: {
                    if filteredItems.count <= 1 {
                        Text("Playback requires at least 2 visible photos.")
                    }
                }
                
                if Bundle.main.bundleIdentifier == "test.org.cornradio.youlog" {
                    Section {
                        Button(action: {
                            showingDevActionConfirmation = true
                        }) {
                            Label(isContinuousCapture ? "停止连续拍照" : "连续拍照测试", systemImage: "camera.badge.clock")
                                .foregroundStyle(.primary)
                        }
                        
                        Button(action: {
                            showingLiquidGlassTest = true
                        }) {
                            Label("Liquid Glass 测试", systemImage: "sparkles")
                                .foregroundStyle(.primary)
                        }
                    } header: {
                        Text("Developer")
                    }
                }
                
                Section {
                    Button(action: { showingSupportDeveloper = true }) {
                        Label("支持", systemImage: "cup.and.saucer")
                            .foregroundStyle(.primary)
                    }
                    
                    Button(action: { showingHelp = true }) {
                        Label(NSLocalizedString("help", comment: ""), systemImage: "questionmark.circle")
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Sheet modifiers
            .sheet(isPresented: $showingThemeSettings) { ThemeSettingsView() }
            .sheet(isPresented: $showingCompressionSettings) { CompressionSettingsView() }
            .sheet(isPresented: $showingDataStats) { DataStatsView(items: items) }
            .sheet(isPresented: $showingImageCleaner) { ImageCleanerView(items: items) }
            .sheet(isPresented: $showingNetworkTransfer) { NetworkTransferView(items: items) }
            .sheet(isPresented: $showingSupportDeveloper) { SupportDeveloperView() }
            .sheet(isPresented: $showingHelp) { HelpView() }
            .sheet(isPresented: $showingLiquidGlassTest) { LiquidGlassTestView() }
            .fullScreenCover(isPresented: $showingPlayback) {
                PlaybackView(items: filteredItems, currentIndex: $currentPlaybackIndex)
            }
            .confirmationDialog("开发功能", isPresented: $showingDevActionConfirmation) {
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
        }
    }
    
    // MARK: - Helper Functions (Moved from MainView)
    
    private func startContinuousCapture() {
        captureCount = 0
        captureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            let newItem = Item(timestamp: Date(),
                             imageData: generateTestImage(),
                             tag: nil)
            modelContext.insert(newItem)
            captureCount += 1
        }
    }
    
    private func stopContinuousCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
    }
    
    private func generateTestImage() -> Data? {
        // Reuse the logic from MainView or move this to a helper/utility if it's complex.
        // For now, I'll simplify or duplicate since it's dev-only code.
        // Actually, let's copy the implementation for completeness as I am moving it.
        
        let screenSize = UIScreen.main.bounds.size
        let imageWidth = screenSize.width * 3
        let imageHeight = imageWidth * 4 / 3
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let colors: [UIColor] = [.systemBlue, .systemPurple, .systemYellow, .systemGreen, .systemOrange, .systemRed, .systemPink, .systemIndigo, .systemTeal, .systemMint]
            let colorIndex = captureCount % colors.count
            let backgroundColor = colors[colorIndex]
            
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let text = "Test Image \(captureCount + 1)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: size.width * 0.05),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(x: (size.width - textSize.width) / 2,
                                y: (size.height - textSize.height) / 2,
                                width: textSize.width,
                                height: textSize.height)
            text.draw(in: textRect, withAttributes: attributes)
        }
        return image.jpegData(compressionQuality: 0.9)
    }
    
}

#Preview {
    SettingsView(viewMode: .constant(0), items: [], filteredItems: [])
}
