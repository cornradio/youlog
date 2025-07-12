import SwiftUI

struct ImageDetailView: View {
    let images: [UIImage]
    @Binding var currentIndex: Int
    @State private var isFlipped: Bool = false

    private var image: UIImage { images[currentIndex] }
    private var imageSize: String {
        let data = image.jpegData(compressionQuality: 0.8)
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ZoomableImageView(image: image, isFlipped: isFlipped)
                .ignoresSafeArea()
                .overlay(bottomMenu(), alignment: .bottom)
        }
    }

    private func bottomMenu() -> some View {
        HStack(spacing: 18) {
            Button(action: navigateToPrevious) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text("\(currentIndex + 1) / \(images.count)")
                .font(.subheadline)
                .foregroundColor(.white)
            Button(action: navigateToNext) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Divider()
                .frame(height: 20)
                .background(Color.white.opacity(0.3))
            Button(action: {
                isFlipped.toggle()
            }) {
                Image(systemName: "arrow.left.and.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Text(imageSize)
                .font(.subheadline)
                .foregroundColor(.white)
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

// UIKit实现的可缩放图片视图
struct ZoomableImageView: UIViewRepresentable {
    let image: UIImage
    let isFlipped: Bool

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
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        if let imageView = scrollView.viewWithTag(99) as? UIImageView {
            imageView.image = image
            imageView.transform = isFlipped ? CGAffineTransform(scaleX: -1, y: 1) : .identity
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(99)
        }
    }
}
