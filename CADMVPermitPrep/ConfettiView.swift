import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    func generateConfetti(in size: CGSize) {
        let colors: [Color] = [
            Color.adaptivePrimaryBlue,
            Color.adaptiveAccentTeal,
            Color.adaptiveAccentYellow,
            Color.adaptiveAccentRed
        ]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...14),
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                )
            )
            particles.append(particle)
        }
        
        animateConfetti(in: size)
    }
    
    func animateConfetti(in size: CGSize) {
        for i in particles.indices {
            withAnimation(.easeOut(duration: Double.random(in: 2...3))) {
                particles[i].position.y = size.height + 20
                particles[i].position.x += CGFloat.random(in: -100...100)
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var color: Color
    var size: CGFloat
    var position: CGPoint
}
