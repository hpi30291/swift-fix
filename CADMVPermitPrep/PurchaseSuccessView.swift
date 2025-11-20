import SwiftUI

struct PurchaseSuccessView: View {
    let onDismiss: () -> Void
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Checkmark animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.adaptiveSuccess.opacity(0.5), radius: 30, x: 0, y: 10)

                    Image(systemName: "checkmark")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .opacity(opacity)

                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 60))

                    Text("You're All Set!")
                        .font(.system(size: 36, weight: .black))
                        .foregroundColor(.white)

                    Text("Full Access Unlocked")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                }
                .opacity(opacity)

                // Feature list
                VStack(alignment: .leading, spacing: 16) {
                    SuccessFeatureRow(icon: "books.vertical.fill", text: "500+ questions")
                    SuccessFeatureRow(icon: "arrow.clockwise", text: "Unlimited tests")
                    SuccessFeatureRow(icon: "brain.head.profile", text: "AI Tutor")
                    SuccessFeatureRow(icon: "book.fill", text: "Learn Mode")
                    SuccessFeatureRow(icon: "star.fill", text: "All features")
                }
                .padding(.horizontal, 32)
                .opacity(opacity)

                // CTA Button
                Button(action: onDismiss) {
                    Text("Start Practicing")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.primaryGradient)
                        .cornerRadius(16)
                        .shadow(color: Color.adaptivePrimaryBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .opacity(opacity)
            }
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color.adaptiveCardBackground)
                    .shadow(color: Color.black.opacity(0.3), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Animate checkmark
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }

            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1.0
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

struct SuccessFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.adaptivePrimaryBlue)
                .frame(width: 32)

            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

#Preview {
    PurchaseSuccessView(onDismiss: {})
}
