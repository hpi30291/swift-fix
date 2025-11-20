import Foundation
import CoreData
import Combine

// MARK: - Data Models for Analytics
struct DailyStats: Identifiable {
    let id = UUID()
    let date: Date
    let questionsAnswered: Int
    let correctAnswers: Int
    let accuracy: Double
    let totalTimeSpent: TimeInterval // in seconds
}

struct WeeklyStats: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let questionsAnswered: Int
    let accuracy: Double
    let timeSpent: TimeInterval
    let daysStudied: Int
}

struct CategoryTrend: Identifiable {
    let id = UUID()
    let category: String
    let date: Date
    let accuracy: Double
    let attempts: Int
}

// MARK: - Analytics Data Manager
class AnalyticsDataManager: ObservableObject {
    static let shared = AnalyticsDataManager()

    private let context: NSManagedObjectContext

    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }

    // MARK: - Daily Stats
    func getDailyStats(days: Int = 30) -> [DailyStats] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let attempts = try context.fetch(fetchRequest)

            // Group by day
            var dailyData: [Date: (total: Int, correct: Int, timeSpent: TimeInterval)] = [:]

            for attempt in attempts {
                guard let timestamp = attempt.timestamp else { continue }
                let dayStart = calendar.startOfDay(for: timestamp)

                let current = dailyData[dayStart] ?? (0, 0, 0)
                dailyData[dayStart] = (
                    current.total + 1,
                    current.correct + (attempt.wasCorrect ? 1 : 0),
                    current.timeSpent + TimeInterval(attempt.timeTaken)
                )
            }

            // Convert to DailyStats array
            var stats: [DailyStats] = []
            for day in 0..<days {
                guard let date = calendar.date(byAdding: .day, value: -day, to: endDate) else { continue }
                let dayStart = calendar.startOfDay(for: date)

                if let data = dailyData[dayStart] {
                    let accuracy = data.total > 0 ? Double(data.correct) / Double(data.total) : 0.0
                    stats.append(DailyStats(
                        date: dayStart,
                        questionsAnswered: data.total,
                        correctAnswers: data.correct,
                        accuracy: accuracy,
                        totalTimeSpent: data.timeSpent
                    ))
                } else {
                    // No data for this day
                    stats.append(DailyStats(
                        date: dayStart,
                        questionsAnswered: 0,
                        correctAnswers: 0,
                        accuracy: 0.0,
                        totalTimeSpent: 0
                    ))
                }
            }

            return stats.reversed() // Oldest to newest
        } catch {
            print("Error fetching daily stats: \(error)")
            return []
        }
    }

    // MARK: - Weekly Stats
    func getWeeklyStats(weeks: Int = 12) -> [WeeklyStats] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .weekOfYear, value: -weeks, to: endDate) else {
            return []
        }

        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let attempts = try context.fetch(fetchRequest)

            // Group by week
            var weeklyData: [Date: (total: Int, correct: Int, timeSpent: TimeInterval, studyDays: Set<Date>)] = [:]

            for attempt in attempts {
                guard let timestamp = attempt.timestamp else { continue }
                guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: timestamp)?.start else { continue }

                let dayStart = calendar.startOfDay(for: timestamp)
                let current = weeklyData[weekStart] ?? (0, 0, 0, Set<Date>())

                var studyDays = current.studyDays
                studyDays.insert(dayStart)

                weeklyData[weekStart] = (
                    current.total + 1,
                    current.correct + (attempt.wasCorrect ? 1 : 0),
                    current.timeSpent + TimeInterval(attempt.timeTaken),
                    studyDays
                )
            }

            // Convert to WeeklyStats array
            var stats: [WeeklyStats] = []
            for week in 0..<weeks {
                guard let date = calendar.date(byAdding: .weekOfYear, value: -week, to: endDate),
                      let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { continue }

                if let data = weeklyData[weekStart] {
                    let accuracy = data.total > 0 ? Double(data.correct) / Double(data.total) : 0.0
                    stats.append(WeeklyStats(
                        weekStartDate: weekStart,
                        questionsAnswered: data.total,
                        accuracy: accuracy,
                        timeSpent: data.timeSpent,
                        daysStudied: data.studyDays.count
                    ))
                }
            }

            return stats.reversed().sorted { $0.weekStartDate < $1.weekStartDate }
        } catch {
            print("Error fetching weekly stats: \(error)")
            return []
        }
    }

    // MARK: - Accuracy Trends
    func getAccuracyTrend(days: Int = 30) -> [DailyStats] {
        return getDailyStats(days: days).filter { $0.questionsAnswered > 0 }
    }

    // MARK: - Study Time Trends
    func getStudyTimeTrend(days: Int = 30) -> [DailyStats] {
        return getDailyStats(days: days).filter { $0.totalTimeSpent > 0 }
    }

    // MARK: - Category Trends
    func getCategoryTrends(category: String, days: Int = 30) -> [CategoryTrend] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@ AND category == %@",
            startDate as NSDate,
            endDate as NSDate,
            category
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let attempts = try context.fetch(fetchRequest)

            // Group by day
            var dailyData: [Date: (total: Int, correct: Int)] = [:]

            for attempt in attempts {
                guard let timestamp = attempt.timestamp else { continue }
                let dayStart = calendar.startOfDay(for: timestamp)

                let current = dailyData[dayStart] ?? (0, 0)
                dailyData[dayStart] = (
                    current.total + 1,
                    current.correct + (attempt.wasCorrect ? 1 : 0)
                )
            }

            // Convert to CategoryTrend array
            return dailyData.map { date, data in
                let accuracy = data.total > 0 ? Double(data.correct) / Double(data.total) : 0.0
                return CategoryTrend(
                    category: category,
                    date: date,
                    accuracy: accuracy,
                    attempts: data.total
                )
            }.sorted { $0.date < $1.date }

        } catch {
            print("Error fetching category trends: \(error)")
            return []
        }
    }

    // MARK: - Aggregate Stats
    func getTotalStudyTime() -> TimeInterval {
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()

        do {
            let attempts = try context.fetch(fetchRequest)
            return attempts.reduce(0) { $0 + TimeInterval($1.timeTaken) }
        } catch {
            print("Error fetching total study time: \(error)")
            return 0
        }
    }

    func getAverageAccuracy() -> Double {
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()

        do {
            let attempts = try context.fetch(fetchRequest)
            guard !attempts.isEmpty else { return 0.0 }

            let correct = attempts.filter { $0.wasCorrect }.count
            return Double(correct) / Double(attempts.count)
        } catch {
            print("Error fetching average accuracy: \(error)")
            return 0.0
        }
    }
}

// MARK: - Helper Extensions
extension TimeInterval {
    var formattedStudyTime: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
