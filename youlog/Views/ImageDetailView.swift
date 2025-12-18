import SwiftUI
import UIKit

struct ImageDetailView: View {
    let items: [Item]  // 修改为 Item 数组，实现延迟加载
    @Environment(\.dismiss) private var dismiss
    @Binding var currentIndex: Int
    @State private var isFlipped: Bool = false
    @State private var showCompressionAlert = false
    @State private var isCompressing = false
    @State private var showCompressionSuccess = false
    @Environment(\.modelContext) private var modelContext
    
    // 压缩完成后的回调
    var onImageCompressed: ((UIImage, Int) -> Void)? = nil

    private var currentImage: UIImage? {
        guard currentIndex >= 0 && currentIndex < items.count,
              let data = items[currentIndex].imageData else { return nil }
        return UIImage(data: data)
    }
    
    private var imageSize: String {
        guard currentIndex >= 0 && currentIndex < items.count,
              let data = items[currentIndex].imageData else { return "0 KB" }
        
        let sizeInBytes = data.count
        if sizeInBytes >= 1024 * 1024 {
            return String(format: "%.1f MB", Double(sizeInBytes) / (1024 * 1024))
        } else {
            return String(format: "%.1f KB", Double(sizeInBytes) / 1024)
        }
    }

    private func navigateToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        } else {
            currentIndex = items.count - 1
        }
    }
    private func navigateToNext() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
    
    private func compressCurrentImage() {
        guard currentIndex < items.count else { return }
        guard let originalImage = currentImage else { return }
        
        isCompressing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 获取原始图片大小
            let settings = CompressionSettings.shared
            guard let originalData = originalImage.jpegData(compressionQuality: settings.compressionQuality) else {
                DispatchQueue.main.async { isCompressing = false }
                return
            }
            let originalSize = originalData.count
            
            if let compressedImage = forceCompressImage(originalImage) {
                // 获取压缩后图片大小
                guard let compressedData = compressedImage.jpegData(compressionQuality: settings.compressionQuality) else {
                    DispatchQueue.main.async { isCompressing = false }
                    return
                }
                let compressedSize = compressedData.count
                
                DispatchQueue.main.async {
                    if compressedSize < originalSize {
                        onImageCompressed?(compressedImage, currentIndex)
                        showCompressionSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCompressionSuccess = false
                        }
                    }
                    isCompressing = false
                }
            } else {
                DispatchQueue.main.async {
                    isCompressing = false
                }
            }
        }
    }
    
    // 修改后的强制压缩函数
    private func forceCompressImage(_ image: UIImage) -> UIImage? {
        let settings = CompressionSettings.shared
        let targetWidth: CGFloat = settings.targetWidth
        let compressionQuality: CGFloat = settings.compressionQuality
        
        let originalSize = image.size
        let shortside = min(originalSize.width, originalSize.height)
        let scale = min(1.0, targetWidth / max(shortside, 1)) 
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        // 重新采样的图片
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true 
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { context in
            context.cgContext.setFillColor(UIColor.black.cgColor)
            context.cgContext.interpolationQuality = .high 
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        guard let data = resizedImage.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: data) else {
            return nil
        }
        
        let cropRect = CGRect(x: 0, y: 0, width: compressedImage.size.width - 1, height: compressedImage.size.height - 1)
        guard let cgImage = compressedImage.cgImage?.cropping(to: cropRect) else {
            return compressedImage
        }
        
        return UIImage(cgImage: cgImage, scale: compressedImage.scale, orientation: compressedImage.imageOrientation)
    }

    private func deleteCurrentItem() {
        guard currentIndex >= 0 && currentIndex < items.count else { return }
        let itemToDelete = items[currentIndex]
        
        if currentIndex < items.count - 1 {
            // 有下一张，跳到下一张再删除
            currentIndex += 1
            modelContext.delete(itemToDelete)
        } else {
            // 是最后一张，直接退出再删除
            dismiss()
            modelContext.delete(itemToDelete)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = currentImage {
                ZoomableImageView(
                    image: img,
                    isFlipped: isFlipped,
                    currentIndex: currentIndex
                )
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom) {
            bottomMenu()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        // .navigationBarBackButtonHidden(true)
    }

    private func bottomMenu() -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 0) {
                // // 1. 关闭
                // Button(action: {
                //     dismiss()
                // }) {
                //     VStack(spacing: 4) {
                //         Image(systemName: "xmark")
                //             .font(.system(size: 20, weight: .medium))
                //         Text("关闭")
                //             .font(.caption2)
                //     }
                //     .foregroundColor(.white.opacity(0.9))
                //     .frame(maxWidth: .infinity)
                //     .padding(.vertical, 10)
                //     .contentShape(Rectangle())
                // }

                                // 5. 分享
                Button(action: {
                    if let img = currentImage {
                        let av = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            av.popoverPresentationController?.sourceView = window
                            av.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                            window.rootViewController?.present(av, animated: true, completion: nil)
                        }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .medium))
                        Text("分享")
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                
                // 2. 上一张
                Button(action: navigateToPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                
                // 3. 状态信息 (点击可压缩)
                Button(action: {
                    showCompressionAlert = true
                }) {
                    VStack(spacing: 2) {
                        Text("\(currentIndex + 1) / \(items.count)")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if isCompressing {
                            ProgressView()
                                .scaleEffect(0.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 12)
                        } else {
                            Text(imageSize)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .disabled(isCompressing)
                
                // 4. 下一张
                Button(action: navigateToNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                

                
                // 6. 删除
                Button(action: {
                    deleteCurrentItem()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                        Text("删除")
                            .font(.caption2)
                    }
                    .foregroundColor(.red.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
            }
            .padding(.bottom, 4) // 适配 Home Indicator
        }

        .background(.ultraThinMaterial)
        .alert("压缩图片", isPresented: $showCompressionAlert) {
            Button("取消", role: .cancel) { }
            Button("压缩") {
                compressCurrentImage()
            }
        } message: {
            Text("压缩后图片质量会降低，是否继续？")
        }
    }
}

// UIKit实现的可缩放图片视图
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let isFlipped: Bool
    let currentIndex: Int // 添加 currentIndex 作为依赖

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        // 关键修正：防止系统自动调整内边距导致图片下移
        scrollView.contentInsetAdjustmentBehavior = .never

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tag = 99
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let imageView = scrollView.viewWithTag(99) as? UIImageView {
            imageView.image = image
            imageView.transform = isFlipped ? CGAffineTransform(scaleX: -1, y: 1) : .identity
            
            // 重要修正：当图片更新时，重置缩放比例
            if scrollView.zoomScale != 1.0 {
                scrollView.setZoomScale(1.0, animated: false)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(99)
        }
        
        // 辅助性：确保缩放时图片居中
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let imageView = scrollView.viewWithTag(99)!
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        }
    }
}
