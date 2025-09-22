import SwiftUI
import Foundation

// 压缩设置数据模型
class CompressionSettings: ObservableObject {
    // 屏幕宽度倍数（0.1-5.0，精度0.1）
    @Published var screenWidthMultiplier: Double {
        didSet {
            UserDefaults.standard.set(screenWidthMultiplier, forKey: "compressionScreenWidthMultiplier")
        }
    }
    
    // 压缩质量（0.1-1.0，精度0.1）
    @Published var compressionQuality: Double {
        didSet {
            UserDefaults.standard.set(compressionQuality, forKey: "compressionQuality")
        }
    }
    
    // 是否启用系统相机拍摄后自动压缩
    @Published var autoCompressSystemCamera: Bool {
        didSet {
            UserDefaults.standard.set(autoCompressSystemCamera, forKey: "autoCompressSystemCamera")
        }
    }
    
    // 是否默认使用系统相机拍照
    @Published var defaultUseSystemCamera: Bool {
        didSet {
            UserDefaults.standard.set(defaultUseSystemCamera, forKey: "defaultUseSystemCamera")
        }
    }
    
    // 单例实例
    static let shared = CompressionSettings()
    
    private init() {
        // 从 UserDefaults 读取保存的设置，设置默认值
        self.screenWidthMultiplier = UserDefaults.standard.object(forKey: "compressionScreenWidthMultiplier") as? Double ?? 3.0
        self.compressionQuality = UserDefaults.standard.object(forKey: "compressionQuality") as? Double ?? 0.8
        self.autoCompressSystemCamera = UserDefaults.standard.bool(forKey: "autoCompressSystemCamera")
        self.defaultUseSystemCamera = UserDefaults.standard.bool(forKey: "defaultUseSystemCamera")
    }
    
    // 获取目标宽度（基于屏幕宽度和倍数）
    var targetWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return screenWidth * screenWidthMultiplier
    }
    
    // 重置为默认设置
    func resetToDefaults() {
        screenWidthMultiplier = 3.0
        compressionQuality = 0.8
        autoCompressSystemCamera = false
        defaultUseSystemCamera = false
    }
}
