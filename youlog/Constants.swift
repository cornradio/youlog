import Foundation

class TagManager: ObservableObject {
    @Published var availableTags: [String] {
        didSet {
            UserDefaults.standard.set(availableTags, forKey: "availableTags")
        }
    }
    
    private let defaultTags = ["全部", "脸型", "身体", "宠物" ,"食物", "生活", "车子", "灵感"]
    
    init() {
        // 检查是否是首次安装
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if isFirstLaunch {
            // 首次安装，使用默认标签
            self.availableTags = defaultTags.sorted()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        } else {
            // 非首次安装，只使用保存的标签
            self.availableTags = UserDefaults.standard.stringArray(forKey: "availableTags") ?? ["全部"]
        }
    }
    
    func addTag(_ tag: String) {
        if !availableTags.contains(tag) {
            availableTags.append(tag)
        }
    }
    
    func deleteTag(_ tag: String) {
        if tag != "全部" {
            availableTags.removeAll { $0 == tag }
        }
    }
}

enum AppConstants {
    static let tagManager = TagManager()
    static var availableTags: [String] {
        tagManager.availableTags
    }
}
