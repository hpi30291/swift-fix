import Foundation
import CoreData
import SwiftUI
import Combine

struct TestHistoryRecord: Identifiable {
    let id: UUID
    let date: Date
    let score: Int
    let totalQuestions: Int
    let timeTaken: Int
    let testType: String
    let category: String?
    let percentage: Int
    let categoryBreakdown: [String: (correct: Int, total: Int)]

    var passed: Bool {
        percentage >= 80
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedTime: String {
        let minutes = timeTaken / 60
        let seconds = timeTaken % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

class TestHistoryManager: ObservableObject {
    static let shared = TestHistoryManager()

    private let context: NSManagedObjectContext
    @Published var recentTests: [TestHistoryRecord] = []

    private init() {
        self.context = PersistenceController.shared.container.viewContext
        loadRecentTests()
    }

    func saveTest(
        score: Int,
        totalQuestions: Int,
        timeTaken: Int,
        testType: String,
        category: String?,
        categoryBreakdown: [String: (correct: Int, total: Int)]
    ) {
        let test = TestHistory(context: context)
        test.id = UUID()
        test.date = Date()
        test.score = Int32(score)
        test.totalQuestions = Int32(totalQuestions)
        test.timeTaken = Int32(timeTaken)
        test.testType = testType
        test.category = category
        test.percentage = Int32((Double(score) / Double(totalQuestions)) * 100)

        // Convert category breakdown to storable format
        var breakdownDict: [String: [String: Int32]] = [:]
        for (cat, stats) in categoryBreakdown {
            breakdownDict[cat] = [
                "correct": Int32(stats.correct),
                "total": Int32(stats.total)
            ]
        }
        test.categoryBreakdown = breakdownDict

        do {
            try context.save()
            loadRecentTests()

            #if DEBUG
            print("✅ Test history saved: \(testType) - \(score)/\(totalQuestions)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Error saving test history: \(error)")
            #endif
        }
    }

    func loadRecentTests(limit: Int = 10) {
        let request: NSFetchRequest<TestHistory> = TestHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit

        do {
            let results = try context.fetch(request)
            recentTests = results.compactMap { convertToRecord($0) }
        } catch {
            #if DEBUG
            print("❌ Error loading test history: \(error)")
            #endif
        }
    }

    func fetchAllTests() -> [TestHistoryRecord] {
        let request: NSFetchRequest<TestHistory> = TestHistory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let results = try context.fetch(request)
            return results.compactMap { convertToRecord($0) }
        } catch {
            #if DEBUG
            print("❌ Error fetching all tests: \(error)")
            #endif
            return []
        }
    }

    func deleteTest(id: UUID) {
        let request: NSFetchRequest<TestHistory> = TestHistory.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        do {
            let results = try context.fetch(request)
            if let test = results.first {
                context.delete(test)
                try context.save()
                loadRecentTests()
            }
        } catch {
            #if DEBUG
            print("❌ Error deleting test: \(error)")
            #endif
        }
    }

    func getAverageScore(lastN: Int = 10) -> Double {
        let tests = Array(fetchAllTests().prefix(lastN))
        guard !tests.isEmpty else { return 0 }

        let totalPercentage = tests.reduce(0) { $0 + $1.percentage }
        return Double(totalPercentage) / Double(tests.count)
    }

    func getTestCountByType() -> [String: Int] {
        let allTests = fetchAllTests()
        var counts: [String: Int] = [:]

        for test in allTests {
            counts[test.testType, default: 0] += 1
        }

        return counts
    }

    private func convertToRecord(_ entity: TestHistory) -> TestHistoryRecord? {
        guard let id = entity.id,
              let date = entity.date,
              let testType = entity.testType else {
            return nil
        }

        // Convert stored breakdown back to usable format
        var breakdown: [String: (correct: Int, total: Int)] = [:]
        if let storedBreakdown = entity.categoryBreakdown as? [String: [String: Int32]] {
            for (cat, stats) in storedBreakdown {
                if let correct = stats["correct"], let total = stats["total"] {
                    breakdown[cat] = (correct: Int(correct), total: Int(total))
                }
            }
        }

        return TestHistoryRecord(
            id: id,
            date: date,
            score: Int(entity.score),
            totalQuestions: Int(entity.totalQuestions),
            timeTaken: Int(entity.timeTaken),
            testType: testType,
            category: entity.category,
            percentage: Int(entity.percentage),
            categoryBreakdown: breakdown
        )
    }
}
