import SwiftUI

struct StudyCalendarView: View {
    @ObservedObject var progressManager = UserProgressManager.shared
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study History")
                .font(.headline)
                .foregroundColor(Color.adaptiveTextPrimary)
            
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(last30Days(), id: \.self) { date in
                    DayCell(date: date, isStudyDay: isStudyDay(date))
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.adaptiveSuccess)
                        .frame(width: 12, height: 12)
                    Text("Studied")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 12, height: 12)
                    Text("Missed")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.adaptiveCardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .padding(.horizontal)
    }
    
    private func last30Days() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        return (0..<30).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: today)
        }.reversed()
    }
    
    private func isStudyDay(_ date: Date) -> Bool {
        progressManager.studyDates.contains { studyDate in
            calendar.isDate(studyDate, inSameDayAs: date)
        }
    }
}

struct DayCell: View {
    let date: Date
    let isStudyDay: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .foregroundColor(isToday ? .white : Color.adaptiveTextPrimary)
            
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(isToday ? Color.adaptivePrimaryBlue : Color.clear)
        .cornerRadius(8)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var dotColor: Color {
        if isStudyDay {
            return Color.adaptiveSuccess
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    StudyCalendarView()
        .padding()
        .onAppear {
            // Add some sample study dates for preview
            let calendar = Calendar.current
            let today = Date()
            UserProgressManager.shared.studyDates = [
                calendar.date(byAdding: .day, value: 0, to: today)!,
                calendar.date(byAdding: .day, value: -1, to: today)!,
                calendar.date(byAdding: .day, value: -2, to: today)!,
                calendar.date(byAdding: .day, value: -4, to: today)!,
                calendar.date(byAdding: .day, value: -7, to: today)!,
                calendar.date(byAdding: .day, value: -10, to: today)!
            ]
        }
}
