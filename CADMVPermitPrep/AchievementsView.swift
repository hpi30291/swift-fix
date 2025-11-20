import SwiftUI

struct AchievementsView: View {
    @ObservedObject private var manager = AchievementManager.shared
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header stats card
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primaryGradient)
                                        .frame(width: 70, height: 70)
                                        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: 8, x: 0, y: 4)

                                    Image(systemName: "trophy.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                        .accessibilityHidden(true)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                                        Text("\(manager.unlockedCount)")
                                            .font(.system(size: 48, weight: .black))
                                            .foregroundColor(Color.adaptiveTextPrimary)

                                        Text("/ \(manager.achievements.count)")
                                            .font(.title2)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                    }

                                    Text("Achievements Unlocked")
                                        .font(.subheadline)
                                        .foregroundColor(Color.adaptiveTextSecondary)
                                }

                                Spacer()
                            }

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.adaptiveSecondaryBackground)
                                        .frame(height: 10)

                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.primaryGradientHorizontal)
                                        .frame(width: geometry.size.width * (Double(manager.unlockedCount) / Double(max(manager.achievements.count, 1))), height: 10)
                                }
                            }
                            .frame(height: 10)
                        }
                        .padding(24)
                        .background(Color.adaptiveCardBackground)
                        .cornerRadius(24)
                        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.15), radius: 15, y: 8)
                        .padding(.horizontal)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(manager.unlockedCount) out of \(manager.achievements.count) achievements unlocked")
                        .accessibilityValue("\(Int(Double(manager.unlockedCount) / Double(max(manager.achievements.count, 1)) * 100))% complete")
                        
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(manager.achievements) { achievement in
                                AchievementCard(achievement: achievement)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.impact(style: .light)
                        dismiss()
                    }
                    .foregroundColor(Color.adaptivePrimaryBlue)
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    @State private var showDetail = false

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            showDetail = true
        }) {
            VStack(spacing: 16) {
                ZStack {
                    // Outer glow
                    if achievement.isUnlocked {
                        Circle()
                            .fill(Color.primaryGradient)
                            .frame(width: 90, height: 90)
                            .blur(radius: 10)
                            .opacity(0.6)
                    }

                    // Main badge circle
                    Circle()
                        .fill(achievement.isUnlocked ?
                              Color.primaryGradient :
                              LinearGradient(colors: [Color.adaptiveSecondaryBackground, Color.adaptiveSecondaryBackground],
                                           startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: achievement.isUnlocked ? Color.adaptivePrimaryBlue.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)

                    // Icon
                    Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                        .font(.system(size: 36))
                        .foregroundColor(achievement.isUnlocked ? .white : Color.adaptiveTextTertiary)
                }

                VStack(spacing: 4) {
                    Text(achievement.name)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(achievement.isUnlocked ? Color.adaptiveTextPrimary : Color.adaptiveTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(height: 32)

                    if achievement.isUnlocked {
                        Text("✓ Unlocked")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveSuccess)
                    }
                }

                // Progress bar for locked achievements
                if !achievement.isUnlocked && achievement.progress > 0 {
                    VStack(spacing: 4) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.adaptiveSecondaryBackground)
                                    .frame(height: 4)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primaryGradientHorizontal)
                                    .frame(width: geometry.size.width * achievement.progressPercentage, height: 4)
                            }
                        }
                        .frame(height: 4)

                        Text("\(achievement.progress)/\(achievement.requirement)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color.adaptiveTextSecondary)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(achievement.isUnlocked ? Color.adaptivePrimaryBlue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .shadow(color: achievement.isUnlocked ? Color.adaptivePrimaryBlue.opacity(0.2) : Color.black.opacity(0.08), radius: 12, y: 6)
        }
        .accessibilityLabel("\(achievement.name): \(achievement.description)")
        .accessibilityHint(achievement.isUnlocked ? "Unlocked" : "Progress: \(achievement.progress) out of \(achievement.requirement)")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showDetail) {
            AchievementDetailView(achievement: achievement)
        }
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                        .font(.system(size: 100))
                        .foregroundColor(achievement.isUnlocked ? Color.adaptiveAccentYellow : Color.gray.opacity(0.5))
                        .shadow(color: achievement.isUnlocked ? Color.adaptiveAccentYellow.opacity(0.3) : .clear, radius: 20)
                    
                    VStack(spacing: 12) {
                        Text(achievement.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.adaptiveTextPrimary)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(Color.adaptiveTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if achievement.isUnlocked {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.adaptiveSuccess)
                            Text("Unlocked!")
                                .font(.headline)
                                .foregroundColor(Color.adaptiveSuccess)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.adaptiveSuccess.opacity(0.1))
                        .cornerRadius(12)
                    } else if achievement.progress > 0 {
                        VStack(spacing: 8) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.adaptivePrimaryBlue, Color.adaptiveAccentTeal],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * achievement.progressPercentage, height: 8)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(achievement.progress)/\(achievement.requirement)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.adaptivePrimaryBlue)
                        }
                        .padding()
                        .frame(maxWidth: 200)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.adaptivePrimaryBlue)
                }
            }
        }
    }
}
