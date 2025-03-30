import SwiftUI

struct ImageDetailView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var isFlipped: Bool = false
    
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
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale) // Zoom
                .offset(offset) // Offset
                .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
        }
        .overlay(bottomMenu(), alignment: .bottom)
    }

    private func bottomMenu() -> some View {
        HStack(spacing: 20) {
            // 镜像翻转按钮
            Button(action: {
                withAnimation {
                    isFlipped.toggle()
                }
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
}
