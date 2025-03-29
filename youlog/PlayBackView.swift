import SwiftUI

struct PlaybackView: View {
    let items: [Item]
    @Binding var currentIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var preloadedImages: [UIImage] = []
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if !preloadedImages.isEmpty {
                Image(uiImage: preloadedImages[currentIndex])
                    .resizable()
                    .scaledToFit()
            }
            
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                
                // 底部控制栏
                HStack(spacing: 10) {
                    // 播放/暂停按钮
                    Button(action: {
                        if isPlaying {
                            timer?.invalidate()
                            timer = nil
                        } else {
                            startTimer()
                        }
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    // 拖动条
                    Slider(value: Binding(
                        get: { Double(currentIndex) },
                        set: { newValue in
                            currentIndex = Int(newValue)
                            if isPlaying {
                                timer?.invalidate()
                                startTimer()
                            }
                        }
                    ), in: 0...Double(items.count - 1), step: 1)
                    .padding(.horizontal)
                    
                    // 当前索引显示
                    Text("\(currentIndex + 1) / \(items.count)")
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            preloadImages()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func preloadImages() {
        preloadedImages = []
        for item in items {
            if let imageData = item.imageData,
               let image = UIImage(data: imageData) {
                preloadedImages.append(image)
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            currentIndex = (currentIndex + 1) % items.count
        }
    }
}