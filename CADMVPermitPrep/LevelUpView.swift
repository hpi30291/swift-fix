import SwiftUI

struct LevelUpView: View {
    let level: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -10
    
    private var levelInfo: (name: String, emoji: String) {
        let manager = UserProgressManager.shared
        return (
            manager.levelNames[level] ?? "Unknown",
            manager.levelBadges[level] ?? "🎯"
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("Level Up!")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                Text(levelInfo.emoji)
                    .font(.system(size: 120))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                
                VStack(spacing: 8) {
                    Text("Level \(level)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(levelInfo.name)
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(opacity)
                
                Text("Keep going!")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(opacity)
            }
            .padding(40)
            
            ConfettiView()
                .opacity(opacity)
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                rotation = 0
            }
            
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1.0
            }
        }
    }
}
