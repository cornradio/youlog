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
        // 对于 “Open In” 方式，系统已经把文件放到 App 的 Inbox，直接读取即可
        do {
            let data = try Data(contentsOf: url)          // 读取图片二进制
            let newItem = Item(timestamp: Date(),
                               imageData: data,
                               note: "Imported from Share")
            // 使用主模型容器的 context 保存
            let context = sharedModelContainer.mainContext
            context.insert(newItem)
            // SwiftData 默认自动保存，若想手动确认可取消注释下面一行
            // try context.save()
            print("Successfully imported image from: \(url)")
        } catch {
            print("Error importing image: \(error)")
        }
    }
}
