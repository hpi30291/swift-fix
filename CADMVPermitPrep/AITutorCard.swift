import SwiftUI

struct AITutorCard: View {
    @StateObject private var claudeAPI = ClaudeAPIService.shared
    @StateObject private var userAccess = UserAccessManager.shared

    var body: some View {
        NavigationLink(destination: AITutorView()) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue.opacity(0.2), Color.adaptiveAccentTeal.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)

                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(Color.adaptivePrimaryBlue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Scout")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.adaptiveTextPrimary)

                            if !userAccess.hasActiveSubscription {
                                Image(systemName: "lock.fill")
                                    .font(.caption)
                                    .foregroundColor(Color.adaptiveAccentYellow)
                            }
                        }

                        if userAccess.hasActiveSubscription {
                            let (_, hourly) = claudeAPI.getRemainingRequests()
                            Text("\(hourly) questions available")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveTextSecondary)
                        } else {
                            Text("Premium Feature")
                                .font(.caption)
                                .foregroundColor(Color.adaptiveAccentYellow)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.adaptivePrimaryBlue)
                }

                // Description
                Text("Chat with Scout for instant help with California driving laws and personalized study recommendations")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveTextSecondary)
                    .lineLimit(2)

                // Quick actions
                HStack(spacing: 12) {
                    QuickActionChip(icon: "questionmark.circle.fill", text: "Ask Question")
                    QuickActionChip(icon: "lightbulb.fill", text: "Get Tips")
                    QuickActionChip(icon: "target", text: "Study Plan")
                }
            }
            .padding(20)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(20)
            .shadow(color: Color.adaptivePrimaryBlue.opacity(0.1), radius: 15, y: 8)
            .padding(.horizontal)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(Color.adaptivePrimaryBlue)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.adaptivePrimaryBlue.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    AITutorCard()
        .padding()
}
