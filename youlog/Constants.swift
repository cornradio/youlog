import Foundation
import SwiftUI

// MARK: - 主题色枚举
enum AppTheme: String, CaseIterable {
    case blue = "蓝色"
    case purple = "紫色"
    case green = "绿色"
    case orange = "橙色"
    case red = "红色"
    case pink = "粉色"
    case indigo = "靛蓝"
    case teal = "青色"
    case standard = "默认"
    
    var color: Color {
        switch self {
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .green:
            return .green
        case .orange:
            return .orange
        case .red:
            return .red
        case .pink:
            return .pink
        case .indigo:
            return .indigo
        case .teal:
            return .teal
        case .standard:
            return .primary
        }
    }
    
    var systemImage: String {
        switch self {
        case .blue:
            return "circle.fill"
        case .purple:
            return "circle.fill"
        case .green:
            return "circle.fill"
        case .orange:
            return "circle.fill"
        case .red:
            return "circle.fill"
        case .pink:
            return "circle.fill"
        case .indigo:
            return "circle.fill"
        case .teal:
            return "circle.fill"
        case .standard:
            return "circle.righthalf.filled" // 使用半圆图标表示自适应/默认
        }
    }
}

// MARK: - 主题管理器
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    @Published var alwaysUseDarkTheme: Bool {
        didSet {
            UserDefaults.standard.set(alwaysUseDarkTheme, forKey: "alwaysUseDarkTheme")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? AppTheme.standard.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .standard
        self.alwaysUseDarkTheme = UserDefaults.standard.bool(forKey: "alwaysUseDarkTheme")
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    func setAlwaysUseDarkTheme(_ enabled: Bool) {
        alwaysUseDarkTheme = enabled
    }
}

// MARK: - 标签管理器
class TagManager: ObservableObject {
    @Published var availableTags: [String] {
        didSet {
            UserDefaults.standard.set(availableTags, forKey: "availableTags")
        }
    }
    
    // 特殊标签的标识符 - 不要翻译这个字符串
    private static let ALL_TAG_IDENTIFIER = "TAG_ALL"
    
    private static var defaultTags: [String] {
        [
            NSLocalizedString("all", comment: ""),
            NSLocalizedString("未分类", comment: ""),
            "脸型", "身体", "宠物", "食物", "生活", "车子", "灵感"
        ]
    }
    
    init() {
        // 检查是否是首次安装
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if isFirstLaunch {
            // 首次安装，使用默认标签
            self.availableTags = TagManager.defaultTags.sorted()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            // 非首次安装，加载保存的标签
            let savedTags = UserDefaults.standard.stringArray(forKey: "availableTags") ?? [NSLocalizedString("all", comment: "")]
            
            // 更新所有标签的语言
            var updatedTags = savedTags
            
            // 查找并更新"全部"标签
            if let index = updatedTags.firstIndex(where: { $0 == "全部" || $0 == "All" }) {
                updatedTags[index] = NSLocalizedString("all", comment: "")
            }
            
            // 确保"全部"标签存在
            let allTag = NSLocalizedString("all", comment: "")
            if !updatedTags.contains(allTag) {
                updatedTags.insert(allTag, at: 0)
            }
            
            // 确保"未分类"标签存在
            let untaggedTag = NSLocalizedString("未分类", comment: "")
            if !updatedTags.contains(untaggedTag) {
                // 将"未分类"标签插入到"全部"标签之后
                if let allIndex = updatedTags.firstIndex(of: allTag) {
                    updatedTags.insert(untaggedTag, at: allIndex + 1)
                } else {
                    updatedTags.append(untaggedTag)
                }
            }
            
            self.availableTags = updatedTags
        }
    }
    
    // 判断是否为"全部"标签的辅助方法
    func isAllTag(_ tag: String) -> Bool {
        return tag == NSLocalizedString("all", comment: "") || tag == "全部" || tag == "All"
    }
    
    // 判断是否为"未分类"标签的辅助方法
    func isUntaggedTag(_ tag: String) -> Bool {
        return tag == NSLocalizedString("未分类", comment: "")
    }
    
    func addTag(_ tag: String) {
        if !availableTags.contains(tag) {
            availableTags.append(tag)
        }
    }
    
    func deleteTag(_ tag: String) {
        // 不允许删除"全部"标签和"未分类"标签
        if !isAllTag(tag) && !isUntaggedTag(tag) {
            availableTags.removeAll { $0 == tag }
        }
    }
    
    // 返回本地化后的"全部"标签
    var allTag: String {
        return NSLocalizedString("all", comment: "")
    }
}

enum AppConstants {
    static let tagManager = TagManager()
    static let themeManager = ThemeManager()
    static var availableTags: [String] {
        tagManager.availableTags
    }
}
