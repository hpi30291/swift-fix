import SwiftUI

struct DailyGoalCard: View {
    @StateObject private var progressManager = UserProgressManager.shared
    @State private var showGoalPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.adaptiveAccentTeal.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: "target")
                            .font(.system(size: 18))
                            .foregroundColor(Color.adaptiveAccentTeal)
                    }

                    Text("Daily Goal")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveTextPrimary)
                }

                Spacer()

                Button(action: {
                    showGoalPicker = true
                }) {
                    HStack(spacing: 4) {
                        Text("\(progressManager.dailyGoal)")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.adaptivePrimaryBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.adaptivePrimaryBlue.opacity(0.1))
                    .cornerRadius(20)
                }
            }

            // Progress bar (horizontal instead of circular)
            VStack(spacing: 12) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(progressManager.questionsAnsweredToday)")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(progressManager.isGoalComplete() ? Color.adaptiveSuccess : Color.adaptiveTextPrimary)

                    Text("/ \(progressManager.dailyGoal)")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.adaptiveSecondaryBackground)
                            .frame(height: 12)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                progressManager.isGoalComplete() ?
                                    LinearGradient(colors: [Color.adaptiveSuccess, Color.adaptiveSuccess.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                                    Color.primaryGradientHorizontal
                            )
                            .frame(width: geometry.size.width * progressManager.dailyProgress(), height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressManager.dailyProgress())
                    }
                }
                .frame(height: 12)

                // Status message
                if progressManager.isGoalComplete() {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.adaptiveSuccess)
                        Text("Goal Complete!")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.adaptiveSuccess)
                        Text("🎉")
                    }
                } else {
                    Text("\(progressManager.dailyGoal - progressManager.questionsAnsweredToday) more to reach your goal")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
        }
        .padding(24)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.adaptiveAccentTeal.opacity(0.15), radius: 15, y: 8)
        .padding(.horizontal)
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerView(selectedGoal: $progressManager.dailyGoal)
        }
    }
}

struct GoalPickerView: View {
    @Binding var selectedGoal: Int
    @Environment(\.dismiss) var dismiss
    
    let goalOptions = [10, 20, 30, 50]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.adaptiveBackground
                    .ignoresSafeArea()
                
                List {
                    ForEach(goalOptions, id: \.self) { goal in
                        Button(action: {
                            UserProgressManager.shared.setDailyGoal(goal)
                            dismiss()
                        }) {
                            HStack {
                                Text("\(goal) questions per day")
                                    .foregroundColor(Color.adaptiveTextPrimary)
                                
                                Spacer()
                                
                                if goal == selectedGoal {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.adaptivePrimaryBlue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Daily Goal")
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

#Preview {
    DailyGoalCard()
        .padding()
}
