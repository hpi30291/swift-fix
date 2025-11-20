import SwiftUI

struct WeakAreasCard: View {
    let weakAreas: [(category: String, accuracy: Double)]

    var body: some View {
        if !weakAreas.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.adaptiveError.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.adaptiveError)
                    }

                    Text("Focus Areas")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)

                    Spacer()

                    Text("\(weakAreas.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.adaptiveError)
                        .cornerRadius(12)
                }

                // Weak categories list
                VStack(spacing: 0) {
                    ForEach(Array(weakAreas.prefix(3).enumerated()), id: \.element.category) { index, area in
                        NavigationLink(destination: QuizView(questionCount: 20, category: area.category)) {
                            HStack(spacing: 16) {
                                // Warning icon
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(categoryColor(for: area.accuracy))

                                // Category info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(area.category)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color.adaptiveTextPrimary)

                                    HStack(spacing: 8) {
                                        // Mini progress bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.adaptiveSecondaryBackground)
                                                    .frame(height: 4)

                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(categoryColor(for: area.accuracy))
                                                    .frame(width: geometry.size.width * area.accuracy, height: 4)
                                            }
                                        }
                                        .frame(width: 60, height: 4)

                                        Text("\(Int(area.accuracy * 100))%")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(Color.adaptiveTextSecondary)
                                    }
                                }

                                Spacer()

                                // Practice button
                                Text("Practice")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.primaryGradient)
                                    .cornerRadius(20)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color.adaptiveInnerBackground)
                        }

                        if index < min(2, weakAreas.count - 1) {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(Color.adaptiveCardBackground)
                .cornerRadius(16)
            }
            .padding(24)
            .background(Color.adaptiveCardBackground)
            .cornerRadius(24)
            .shadow(color: Color.adaptiveError.opacity(0.15), radius: 15, y: 8)
            .padding(.horizontal)
        }
    }

    private func categoryColor(for accuracy: Double) -> Color {
        if accuracy < 0.6 {
            return Color.adaptiveError
        } else if accuracy < 0.8 {
            return Color.adaptiveAccentYellow
        } else {
            return Color.adaptiveAccentYellow
        }
    }
}



