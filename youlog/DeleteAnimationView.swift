import SwiftUI

struct DeleteAnimationView: View {
    let image: UIImage
    @Binding var isAnimating: Bool
    let onComplete: () -> Void
    
    @State private var particles: [Particle] = []
    @State private var opacity: Double = 1.0
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var scale: CGFloat
        var rotation: Double
        var opacity: Double
    }
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .opacity(opacity)
            
            ForEach(particles) { particle in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .position(particle.position)
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // 创建粒子
        let imageSize = image.size
        let particleCount = 50
        
        for _ in 0..<particleCount {
            let particle = Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...imageSize.width),
                    y: CGFloat.random(in: 0...imageSize.height)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: -100...100)
                ),
                scale: CGFloat.random(in: 0.1...0.3),
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)
        }
        
        // 开始动画
        withAnimation(.easeOut(duration: 1.0)) {
            opacity = 0
            isAnimating = true
        }
        
        // 粒子动画
        for (index, _) in particles.enumerated() {
            withAnimation(.easeOut(duration: 1.0)) {
                particles[index].position.x += particles[index].velocity.x
                particles[index].position.y += particles[index].velocity.y
                particles[index].scale *= 0.5
                particles[index].rotation += Double.random(in: 180...360)
                particles[index].opacity = 0
            }
        }
        
        // 动画完成后调用回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete()
        }
    }
} 