import Foundation

class TagManager: ObservableObject {
    @Published var availableTags: [String] {
        didSet {
            UserDefaults.standard.set(availableTags, forKey: "availableTags")
        }
    }
    
    init() {
        self.availableTags = UserDefaults.standard.stringArray(forKey: "availableTags") ?? ["全部"]
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
