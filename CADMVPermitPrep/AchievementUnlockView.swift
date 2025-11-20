import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 24) {
                Text("Achievement Unlocked!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(opacity)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 100))
                    .foregroundColor(Color.adaptiveAccentYellow)
                    .scaleEffect(scale)
                    .shadow(color: Color.adaptiveAccentYellow.opacity(0.5), radius: 20)
                
                VStack(spacing: 8) {
                    Text(achievement.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                .opacity(opacity)
                
                Button(action: dismiss) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .opacity(opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.adaptiveCardBackground)
                    .shadow(color: .black.opacity(0.3), radius: 30)
            )
            .padding(32)
            
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1.0
            }
            
            showConfetti = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showConfetti = false
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}



