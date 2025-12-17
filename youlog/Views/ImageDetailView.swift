import SwiftUI
import UIKit // 确保导入UIKit，因为UIImage和UIGraphicsImageRenderer都在其中

struct ImageDetailView: View {
    let images: [UIImage]  // 图片数组
    @Environment(\.dismiss) private var dismiss
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
        let settings = CompressionSettings.shared
        let data = image.jpegData(compressionQuality: settings.compressionQuality)
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
            let settings = CompressionSettings.shared
            guard let originalData = originalImage.jpegData(compressionQuality: settings.compressionQuality) else {
                DispatchQueue.main.async {
                    isCompressing = false
                }
                return
            }
            let originalSize = originalData.count
            
            if let compressedImage = forceCompressImage(originalImage) {
                // 获取压缩后图片大小
                guard let compressedData = compressedImage.jpegData(compressionQuality: settings.compressionQuality) else {
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
                    showCompressionSuccess = false
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
        // 以“最长边不超过 targetWidth”为准，保持纵横比；不放大
        let shortside = min(originalSize.width, originalSize.height)
        let scale = min(1.0, targetWidth / max(shortside, 1)) 
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
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
            Color.black.ignoresSafeArea()

            ZoomableImageView(
                image: image,
                isFlipped: isFlipped,
                currentIndex: currentIndex
            ) 
//            .ignoresSafeArea()
            .overlay(bottomMenu(), alignment: .bottom) // 菜单覆盖在底部
        }
        .navigationBarBackButtonHidden(true)
    }

    private func bottomMenu() -> some View {
        HStack(spacing: 18) {
            // Close Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
                
            Button(action: navigateToPrevious) {
                Image(systemName: "chevron.left.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text("\(currentIndex + 1) / \(images.count)")
                .font(.subheadline)
                .foregroundColor(.white)
            Button(action: navigateToNext) {
                Image(systemName: "chevron.right.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            // Button(action: { //反转 功能失效，备注
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
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }

        .padding(.horizontal, 20)
        .padding(.vertical, 12)
     .clipShape(Capsule())
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
