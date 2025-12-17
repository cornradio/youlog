//
//  youlogApp.swift
//  youlog
//
//  Created by kasusa on 2025/3/28.
//

import SwiftUI
import SwiftData

@main
struct youlogApp: App {
    @StateObject private var themeManager = AppConstants.themeManager
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(themeManager.alwaysUseDarkTheme ? .dark : nil)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func handleIncomingURL(_ url: URL) {
        // 启动安全访问（针对某些系统文件或截图）
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // 使用 NSFileCoordinator 读取文件，确保文件访问安全
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { readUrl in
            do {
                let data = try Data(contentsOf: readUrl)
                
                // 尝试创建图片以验证数据有效性
                if let _ = UIImage(data: data) {
                    // 必须在主线程执行 UI/Data 操作
                    DispatchQueue.main.async {
                        // 获取文件名作为备注
                        let filename = url.lastPathComponent
                        let newItem = Item(timestamp: Date(),
                                           imageData: data,
                                           note: "导入: \(filename)")
                        let context = sharedModelContainer.mainContext
                        context.insert(newItem)
                        print("Successfully imported image: \(filename)")
                    }
                } else {
                    print("Imported file is not a valid image: \(readUrl)")
                }
            } catch {
                print("Error reading data: \(error)")
            }
        }
        
        if let error = error {
            print("File coordinator error: \(error)")
        }
    }
}
