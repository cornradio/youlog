import SwiftUI

struct ImageDetailView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Background color
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale) // Zoom
                .offset(offset) // Offset
        }
        .overlay(shareButton(), alignment: .bottom)
    }

    //sharebutton
    private func shareButton() -> some View {
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
                .font(.title)
                .foregroundColor(.white)
                .padding()
        }
    }
}
