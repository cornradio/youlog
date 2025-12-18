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
    
    // 是否启用从相册导入后自动压缩
    @Published var autoCompressAlbumImport: Bool {
        didSet {
            UserDefaults.standard.set(autoCompressAlbumImport, forKey: "autoCompressAlbumImport")
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
        self.autoCompressAlbumImport = UserDefaults.standard.bool(forKey: "autoCompressAlbumImport")
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
        autoCompressAlbumImport = false
    }
    
    // 统一的图片压缩处理方法
    func compressImage(_ image: UIImage) -> Data? {
        let targetWidth = self.targetWidth
        let compressionQuality = self.compressionQuality
        
        let originalSize = image.size
        
        var newSize: CGSize
        if originalSize.width > targetWidth {
            let ratio = targetWidth / originalSize.width
            newSize = CGSize(
                width: targetWidth,
                height: originalSize.height * ratio
            )
        } else {
            newSize = originalSize
        }
        
        // 使用 UIGraphicsImageRenderer 处理缩放
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { context in
            // 填充黑色背景
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))
            
            // 设置高质量插值
            context.cgContext.interpolationQuality = .high
            
            // 绘制图片
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 应用质量压缩
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: compressedData) else {
            return resizedImage.jpegData(compressionQuality: compressionQuality)
        }
        
        // 裁切右边和下面1px (解决某些情况下的边缘白线/黑线问题)
        guard let cgImage = compressedImage.cgImage else { 
            return compressedData 
        }
        
        let cropRect = CGRect(
            x: 0,
            y: 0,
            width: max(1, cgImage.width - 1),
            height: max(1, cgImage.height - 1)
        )
        
        if let croppedCGImage = cgImage.cropping(to: cropRect) {
            let finalImage = UIImage(cgImage: croppedCGImage, scale: compressedImage.scale, orientation: compressedImage.imageOrientation)
            return finalImage.jpegData(compressionQuality: compressionQuality)
        }
        
        return compressedData
    }
}
