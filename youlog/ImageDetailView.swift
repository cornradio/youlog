import SwiftUI

struct ImageDetailView: View {
    let images: [UIImage]  // 改为图片数组
    @Binding var currentIndex: Int  // 当前查看的图片索引，使用绑定以便可以在外部更新
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isFlipped: Bool = false
    
    // 当前显示的图片
    private var image: UIImage {
        images[currentIndex]
    }
    
    // 检查是否有前一张或后一张图片
    private var hasPrevious: Bool {
        currentIndex > 0
    }
    
    private var hasNext: Bool {
        currentIndex < images.count - 1
    }
    
    private var imageSize: String {
        let data = image.jpegData(compressionQuality: 0.8)
        let sizeInBytes = data?.count ?? 0
        if sizeInBytes >= 1024 * 1024 {
            return String(format: "%.1f MB", Double(sizeInBytes) / (1024 * 1024))
        } else {
            return String(format: "%.1f KB", Double(sizeInBytes) / 1024)
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Background color
            
            // 图片显示
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale) // Zoom
                .offset(offset) // Offset
                .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            if scale < 1 {
                                scale = 1
                            }
                        }
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { _ in
                            offset = .zero
                        }
                )
                .gesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if scale > 1 {
                                resetZoom()
                            } else {
                                scale = 2.0
                            }
                        }
                )
        }
        .overlay(bottomMenu(), alignment: .bottom)
    }

    private func bottomMenu() -> some View {
        HStack(spacing: 18) {
            // 左导航按钮
            Button(action: {
                if hasPrevious {
                    currentIndex -= 1
                    resetZoom()
                }
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(hasPrevious ? .white : .gray.opacity(0.5))
            }
            .disabled(!hasPrevious)
            
            // 图片计数
            Text("\(currentIndex + 1) / \(images.count)")
                .font(.subheadline)
                .foregroundColor(.white)
            
            // 右导航按钮
            Button(action: {
                if hasNext {
                    currentIndex += 1
                    resetZoom()
                }
            }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(hasNext ? .white : .gray.opacity(0.5))
            }
            .disabled(!hasNext)
            
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            
            // 镜像翻转按钮
            Button(action: {
                isFlipped.toggle()
            }) {
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // 图片大小显示
            Text(imageSize)
                .font(.subheadline)
                .foregroundColor(.white)
            
            // 分享按钮
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
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
        .padding(.bottom, 20)
    }
    
    // 重置缩放和偏移
    private func resetZoom() {
        scale = 1.0
        offset = .zero
    }
}
