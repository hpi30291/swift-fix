import SwiftUI

struct PointsLevelCard: View {
    @StateObject private var progressManager = UserProgressManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            // Level badge with gradient
            ZStack {
                Circle()
                    .fill(Color.primaryGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: 8, x: 0, y: 4)

                VStack(spacing: 2) {
                    Text(progressManager.currentLevelInfo.emoji)
                        .font(.system(size: 32))

                    Text("LV\(progressManager.currentLevel)")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                // Title and points
                VStack(alignment: .leading, spacing: 4) {
                    Text(progressManager.currentLevelInfo.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(Color.adaptiveAccentYellow)

                        Text("\(progressManager.totalPoints) points")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                }

                // Progress to next level
                if let nextLevel = progressManager.nextLevelInfo {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Next: \(nextLevel.emoji) \(nextLevel.name)")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)

                            Spacer()

                            Text("\(progressManager.pointsToNextLevel)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptivePrimaryBlue)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.primaryGradientHorizontal)
                                    .frame(width: geometry.size.width * progressManager.progressToNextLevel, height: 6)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressManager.progressToNextLevel)
                            }
                        }
                        .frame(height: 6)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color.adaptiveAccentYellow)
                        Text("Max Level Reached!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveSuccess)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.15), radius: 15, y: 8)
        .padding(.horizontal)
    }
}
