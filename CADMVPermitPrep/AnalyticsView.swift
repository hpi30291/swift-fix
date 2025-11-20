import SwiftUI
import Charts

struct AnalyticsView: View {
    @StateObject private var analyticsManager = AnalyticsDataManager.shared
    @State private var selectedTimeRange: TimeRange = .month
    @State private var dailyStats: [DailyStats] = []
    @State private var weeklyStats: [WeeklyStats] = []

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    // Accuracy Trend Chart
                    accuracyTrendSection

                    // Study Time Chart
                    studyTimeSection

                    // Weekly Summary Stats
                    weeklySummarySection
                }
                .padding(.vertical)
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadData()
            }
            .onChange(of: selectedTimeRange) {
                loadData()
            }
        }
    }

    // MARK: - Accuracy Trend Section
    private var accuracyTrendSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accuracy Trend")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .padding(.horizontal)

            if dailyStats.filter({ $0.questionsAnswered > 0 }).isEmpty {
                emptyStateView(message: "No data yet. Start practicing to see your accuracy trends!")
            } else {
                VStack(spacing: 12) {
                    // Chart
                    Chart {
                        ForEach(dailyStats.filter { $0.questionsAnswered > 0 }) { stat in
                            LineMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Accuracy", stat.accuracy * 100)
                            )
                            .foregroundStyle(Color.adaptivePrimaryBlue)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Accuracy", stat.accuracy * 100)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue.opacity(0.3), Color.adaptivePrimaryBlue.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }

                        // Target line at 80%
                        RuleMark(y: .value("Pass", 80))
                            .foregroundStyle(Color.adaptiveSuccess.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Pass: 80%")
                                    .font(.caption2)
                                    .foregroundColor(Color.adaptiveSuccess)
                            }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: 0...100)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)%")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()

                    // Stats summary
                    HStack(spacing: 20) {
                        AnalyticsStatCard(
                            title: "Current",
                            value: String(format: "%.0f%%", (dailyStats.last?.accuracy ?? 0) * 100),
                            color: Color.adaptivePrimaryBlue
                        )

                        AnalyticsStatCard(
                            title: "Average",
                            value: String(format: "%.0f%%", averageAccuracy * 100),
                            color: Color.adaptiveAccentTeal
                        )

                        AnalyticsStatCard(
                            title: "Best",
                            value: String(format: "%.0f%%", (dailyStats.max(by: { $0.accuracy < $1.accuracy })?.accuracy ?? 0) * 100),
                            color: Color.adaptiveSuccess
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 15, y: 8)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Study Time Section
    private var studyTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Time")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .padding(.horizontal)

            if dailyStats.filter({ $0.totalTimeSpent > 0 }).isEmpty {
                emptyStateView(message: "No study time recorded yet. Start practicing to track your progress!")
            } else {
                VStack(spacing: 12) {
                    // Chart
                    Chart {
                        ForEach(dailyStats.filter { $0.totalTimeSpent > 0 }) { stat in
                            BarMark(
                                x: .value("Date", stat.date, unit: .day),
                                y: .value("Minutes", stat.totalTimeSpent / 60)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.adaptivePrimaryBlue, Color.adaptivePrimaryBlueDark],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(4)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: selectedTimeRange == .week ? .day : .weekOfYear)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let intValue = value.as(Int.self) {
                                    Text("\(intValue)m")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .padding()

                    // Stats summary
                    HStack(spacing: 20) {
                        AnalyticsStatCard(
                            title: "Total",
                            value: totalStudyTime.formattedStudyTime,
                            color: Color.adaptivePrimaryBlue
                        )

                        AnalyticsStatCard(
                            title: "Avg/Day",
                            value: averageStudyTimePerDay.formattedStudyTime,
                            color: Color.adaptiveAccentTeal
                        )

                        AnalyticsStatCard(
                            title: "Questions",
                            value: "\(totalQuestions)",
                            color: Color.adaptiveSuccess
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color.adaptiveCardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 15, y: 8)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Weekly Summary Section
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Summary")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.adaptiveTextPrimary)
                .padding(.horizontal)

            if weeklyStats.isEmpty {
                emptyStateView(message: "No weekly data available yet")
            } else {
                VStack(spacing: 12) {
                    ForEach(weeklyStats.prefix(4)) { week in
                        WeeklySummaryRow(stats: week)
                    }
                }
                .padding()
                .background(Color.adaptiveCardBackground)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.08), radius: 15, y: 8)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Empty State
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundColor(Color.adaptiveTextSecondary.opacity(0.5))

            Text(message)
                .font(.subheadline)
                .foregroundColor(Color.adaptiveTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.adaptiveCardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    // MARK: - Computed Properties
    private var averageAccuracy: Double {
        let validStats = dailyStats.filter { $0.questionsAnswered > 0 }
        guard !validStats.isEmpty else { return 0 }
        return validStats.map { $0.accuracy }.reduce(0, +) / Double(validStats.count)
    }

    private var totalStudyTime: TimeInterval {
        dailyStats.reduce(0) { $0 + $1.totalTimeSpent }
    }

    private var averageStudyTimePerDay: TimeInterval {
        let daysWithData = dailyStats.filter { $0.totalTimeSpent > 0 }.count
        guard daysWithData > 0 else { return 0 }
        return totalStudyTime / Double(daysWithData)
    }

    private var totalQuestions: Int {
        dailyStats.reduce(0) { $0 + $1.questionsAnswered }
    }

    // MARK: - Data Loading
    private func loadData() {
        dailyStats = analyticsManager.getDailyStats(days: selectedTimeRange.days)
        weeklyStats = analyticsManager.getWeeklyStats(weeks: selectedTimeRange.days / 7)
    }
}

// MARK: - Analytics Stat Card
struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Color.adaptiveTextSecondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Weekly Summary Row
struct WeeklySummaryRow: View {
    let stats: WeeklyStats

    private var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let startDate = formatter.string(from: stats.weekStartDate)

        let calendar = Calendar.current
        if let endDate = calendar.date(byAdding: .day, value: 6, to: stats.weekStartDate) {
            let endDateStr = formatter.string(from: endDate)
            return "\(startDate) - \(endDateStr)"
        }
        return startDate
    }

    var body: some View {
        HStack(spacing: 16) {
            // Week label
            VStack(alignment: .leading, spacing: 4) {
                Text(weekLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.adaptiveTextPrimary)

                Text("\(stats.daysStudied) days studied")
                    .font(.caption)
                    .foregroundColor(Color.adaptiveTextSecondary)
            }

            Spacer()

            // Stats
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(stats.questionsAnswered)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptivePrimaryBlue)
                    Text("questions")
                        .font(.caption2)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f%%", stats.accuracy * 100))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.adaptiveSuccess)
                    Text("accuracy")
                        .font(.caption2)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.adaptiveInnerBackground)
        .cornerRadius(12)
    }
}

#Preview {
    AnalyticsView()
}
