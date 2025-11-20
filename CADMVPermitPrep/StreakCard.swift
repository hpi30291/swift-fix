import SwiftUI

struct StreakCard: View {
    @StateObject private var progressManager = UserProgressManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // Flame icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [streakIconColor, streakIconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: streakIconColor.opacity(0.4), radius: 8, x: 0, y: 4)

                Text("🔥")
                    .font(.system(size: 40))
                    .scaleEffect(progressManager.currentStreak > 0 ? 1.0 : 0.8)
                    .opacity(progressManager.currentStreak > 0 ? 1.0 : 0.6)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: progressManager.currentStreak)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(progressManager.currentStreak)")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(Color.adaptiveTextPrimary)

                    Text("Day\(progressManager.currentStreak == 1 ? "" : "s")")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveTextSecondary)
                        .padding(.top, 8)
                }

                Text(streakMessage)
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: streakIconColor.opacity(0.2), radius: 15, y: 8)
        .padding(.horizontal)
    }
    
    private var streakMessage: String {
        if progressManager.currentStreak == 0 {
            return "Answer a question to start your streak!"
        } else if progressManager.currentStreak == 1 {
            return "Great start! Keep it going!"
        } else if progressManager.currentStreak < 7 {
            return "You're on fire! Keep studying daily!"
        } else if progressManager.currentStreak < 14 {
            return "Amazing consistency! 🌟"
        } else if progressManager.currentStreak < 30 {
            return "Incredible dedication! 💪"
        } else {
            return "Legendary streak! 👑"
        }
    }
    
    private var streakIconColor: Color {
        if progressManager.currentStreak == 0 {
            return Color.gray
        } else if progressManager.currentStreak < 7 {
            return Color.adaptiveAccentYellow
        } else if progressManager.currentStreak < 30 {
            return Color.orange
        } else {
            return Color.adaptiveError
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakCard()
        
        // Preview with different streak values
        StreakCard()
            .onAppear {
                UserProgressManager.shared.currentStreak = 15
            }
    }
    .padding()
}
