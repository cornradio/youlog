import SwiftUI
import UIKit // 确保导入UIKit，因为UIImage和UIGraphicsImageRenderer都在其中

struct ImageDetailView: View {
    let images: [UIImage]  // 图片数组
    @Binding var currentIndex: Int  // 当前显示的图片索引
    @State private var isFlipped: Bool = false
    @State private var showCompressionAlert = false
    @State private var isCompressing = false
    @State private var showCompressionSuccess = false
    
    // 压缩完成后的回调
    var onImageCompressed: ((UIImage, Int) -> Void)? = nil

    private var image: UIImage { images[currentIndex] }
    
    // 修正：直接计算当前图片的实际文件大小（如果已经压缩，就是压缩后的；如果未压缩，就是原始的）
    private var imageSize: String {
        // 使用jpegData的默认质量或一个统一的质量来获取实际大小，
        // 或者更准确的方法是存储图片时记录其编码大小。
        // 为了演示，这里我们用一个默认的质量再次编码来估算当前显示图片的文件大小。
        // 如果图片是PNG或其他格式，这里需要调整。假设都是JPEG。
        let data = image.jpegData(compressionQuality: 0.8) // 使用一个固定质量来估算当前显示图片的大小
        let sizeInBytes = data?.count ?? 0
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
            currentIndex = images.count - 1
        }
    }
    private func navigateToNext() {
        if currentIndex < images.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = 0
        }
    }
    
    private func compressCurrentImage() {
        guard currentIndex < images.count else { return }
        
        isCompressing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let originalImage = images[currentIndex]
            
            // 获取原始图片大小
            guard let originalData = originalImage.jpegData(compressionQuality: 0.8) else {
                DispatchQueue.main.async {
                    isCompressing = false
                }
                return
            }
            let originalSize = originalData.count
            
            if let compressedImage = forceCompressImage(originalImage) {
                // 获取压缩后图片大小
                guard let compressedData = compressedImage.jpegData(compressionQuality: 0.8) else {
                    DispatchQueue.main.async {
                        isCompressing = false
                    }
                    return
                }
                let compressedSize = compressedData.count
                
                DispatchQueue.main.async {
                    // 只有压缩后文件更小时才替换
                    if compressedSize < originalSize {
                        // 通过回调通知父视图更新图片
                        onImageCompressed?(compressedImage, currentIndex)
                        showCompressionSuccess = true
                        
                        // 2秒后自动隐藏成功提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCompressionSuccess = false
                        }
                    } else {
                        // 压缩后文件更大，不进行替换
                        // 可以显示提示：文件已经很小，无需压缩
                    }
                    isCompressing = false
                }
            } else {
                DispatchQueue.main.async {
                    isCompressing = false
                    // 可以在这里显示压缩失败的提示
                }
            }
        }
    }
    
    // 修改后的强制压缩函数
    private func forceCompressImage(_ image: UIImage) -> UIImage? {
        // 使用设置中的压缩参数
        let settings = CompressionSettings.shared
        let targetWidth: CGFloat = settings.targetWidth
        let compressionQuality: CGFloat = settings.compressionQuality
        
        let originalSize = image.size
        
        var newSize: CGSize
        if originalSize.width > targetWidth {
            let ratio = targetWidth / originalSize.width
            newSize = CGSize(
                width: targetWidth,
                height: originalSize.height * ratio
            )
        } else {
            // 如果原始宽度小于目标宽度，也根据比例缩小，但至少保持一定的尺寸，
            // 关键在于后续的质量压缩。或者也可以选择不尺寸缩放，只质量压缩。
            // 这里为了确保有尺寸压缩，统一按照比例缩放。
            // 更好的做法是设定一个最大宽度/高度限制，如果超出就缩放。
             newSize = originalSize // 不进行尺寸放大，只进行质量压缩
        }
        
        // 重新采样的图片
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true // 设置为不透明，避免白色背景
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { context in
            // 填充背景色为黑色，避免白线
            context.cgContext.setFillColor(UIColor.black.cgColor)
//            context.cgContext(CGRect(origin: .zero, size: newSize))
            
            context.cgContext.interpolationQuality = .high // 使用高质量插值，以得到更好的缩放结果
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // 进一步进行JPEG质量压缩
        guard let data = resizedImage.jpegData(compressionQuality: compressionQuality),
              let compressedImage = UIImage(data: data) else {
            return nil
        }
        
        // 裁切右边和下面1px避免白线
        let cropRect = CGRect(x: 0, y: 0, width: compressedImage.size.width - 1, height: compressedImage.size.height - 1)
        guard let cgImage = compressedImage.cgImage?.cropping(to: cropRect) else {
            return compressedImage
        }
        
        return UIImage(cgImage: cgImage, scale: compressedImage.scale, orientation: compressedImage.imageOrientation)
    }

    var body: some View {
        ZStack {
            // Color.black.ignoresSafeArea()
            ZoomableImageView(image: image, isFlipped: isFlipped, currentIndex: currentIndex) // 传入 currentIndex
                // .ignoresSafeArea()
                
                .overlay(bottomMenu(), alignment: .bottom)
            Spacer()
        }
    }

    private func bottomMenu() -> some View {
        HStack(spacing: 18) {
            Button(action: navigateToPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text("\(currentIndex + 1) / \(images.count)")
                .font(.subheadline)
                .foregroundColor(.white)
            Button(action: navigateToNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            // Button(action: { //反转
            //     isFlipped.toggle()
            // }) {
            //     Image(systemName: "arrow.left.and.right") fill
            //         .font(.title2)
            //         .foregroundColor(.white)
            // }
            HStack {
                if isCompressing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                Button(action: {
                    showCompressionAlert = true
                }) {
                    Text(imageSize)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .disabled(isCompressing)
            }
            Button(action: {
                let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    av.popoverPresentationController?.sourceView = window
                    av.popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    window.rootViewController?.present(av, animated: true, completion: nil)
                }
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }

        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        // .clipShape(Capsule())
        .glassEffect()
        // .padding(.bottom, 20)
        .alert("压缩图片", isPresented: $showCompressionAlert) {
            Button("取消", role: .cancel) { }
            Button("压缩") {
                compressCurrentImage()
            }
        } message: {
            Text("压缩后图片质量会降低，但文件大小会减小。是否继续？")
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

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tag = 99
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // 修正：约束 should be to scrollView's frameLayoutGuide
        // 或者直接让 imageView 的大小等于 scrollView 的 contentSize
        // 为了简单起见，这里让 imageView 填充 scrollView 的可视区域
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            // Important: These two constraints make the image view "center" in the scroll view's content area
            // and act as the content size for the scroll view. Without them, zooming might behave unexpectedly.
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
