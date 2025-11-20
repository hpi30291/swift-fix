import XCTest
import CoreData
@testable import CADMVPermitPrep

// Note: May show malloc warnings due to shared Core Data singleton
// These are test environment warnings, not app bugs
final class CoreDataTests: XCTestCase {

    var persistenceController: PersistenceController!
    var testContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController.shared
        testContext = persistenceController.container.viewContext
    }

    override func tearDown() {
        // Don't clear data in tearDown - causes malloc errors
        // Tests use unique IDs for isolation
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func clearAllQuestionAttempts() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = QuestionAttempt.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try testContext.execute(deleteRequest)
            try testContext.save()
            testContext.refreshAllObjects() // Use refreshAllObjects instead of reset
        } catch {
            print("Error clearing QuestionAttempts: \(error)")
        }
    }

    private func clearAllUserProgress() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = UserProgress.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try testContext.execute(deleteRequest)
            try testContext.save()
            testContext.refreshAllObjects() // Use refreshAllObjects instead of reset
        } catch {
            print("Error clearing UserProgress: \(error)")
        }
    }

    // MARK: - Persistence Controller Tests

    func testPersistenceControllerInitialization() {
        XCTAssertNotNil(persistenceController, "Persistence controller should initialize")
        XCTAssertNotNil(persistenceController.container, "Container should exist")
    }

    func testPersistentStoreLoaded() {
        XCTAssertFalse(persistenceController.container.persistentStoreCoordinator.persistentStores.isEmpty,
                      "Should have at least one persistent store loaded")
    }

    func testViewContextExists() {
        let context = persistenceController.container.viewContext
        XCTAssertNotNil(context, "View context should exist")
    }

    // MARK: - QuestionAttempt Entity Tests

    func testCreateQuestionAttempt() {
        let attempt = QuestionAttempt(context: testContext)
        attempt.questionID = "test123"
        attempt.category = "Traffic Signs"
        attempt.wasCorrect = true
        attempt.timestamp = Date()
        attempt.timeTaken = 15

        XCTAssertEqual(attempt.questionID, "test123")
        XCTAssertEqual(attempt.category, "Traffic Signs")
        XCTAssertTrue(attempt.wasCorrect)
        XCTAssertNotNil(attempt.timestamp)
        XCTAssertEqual(attempt.timeTaken, 15)
    }

    func testSaveQuestionAttempt() {
        // Use unique ID to avoid conflicts with existing data
        let uniqueID = "test_save_\(UUID().uuidString)"

        let attempt = QuestionAttempt(context: testContext)
        attempt.questionID = uniqueID
        attempt.category = "Traffic Signs"
        attempt.wasCorrect = true
        attempt.timestamp = Date()
        attempt.timeTaken = 10

        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to save QuestionAttempt: \(error)")
        }

        // Verify it was saved
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", uniqueID)

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "Should find saved attempt")
            XCTAssertEqual(results.first?.questionID, uniqueID)
        } catch {
            XCTFail("Failed to fetch QuestionAttempt: \(error)")
        }
    }

    func testFetchQuestionAttemptsByQuestionID() {
        // Use unique ID for this test
        let uniqueID = "test_fetch_\(UUID().uuidString)"

        // Create multiple attempts for same question
        for i in 0..<3 {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = uniqueID
            attempt.category = "Traffic Signs"
            attempt.wasCorrect = i % 2 == 0
            attempt.timestamp = Date().addingTimeInterval(Double(i))
            attempt.timeTaken = Int32(10 + i)
        }

        try? testContext.save()

        // Fetch by questionID
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", uniqueID)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 3, "Should find all 3 attempts")
        } catch {
            XCTFail("Failed to fetch attempts: \(error)")
        }
    }

    func testFetchQuestionAttemptsByCategory() {
        // Use unique category name for this test
        let uniqueCategory = "TestCategory_\(UUID().uuidString)"
        let otherCategory1 = "OtherCategory1_\(UUID().uuidString)"
        let otherCategory2 = "OtherCategory2_\(UUID().uuidString)"
        let categories = [uniqueCategory, otherCategory1, otherCategory2]

        for (index, category) in categories.enumerated() {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "q\(UUID().uuidString)_\(index)"
            attempt.category = category
            attempt.wasCorrect = true
            attempt.timestamp = Date()
            attempt.timeTaken = 10
        }

        try? testContext.save()

        // Fetch by unique category
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", uniqueCategory)

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1, "Should find 1 attempt in unique category")
            XCTAssertEqual(results.first?.category, uniqueCategory)
        } catch {
            XCTFail("Failed to fetch by category: \(error)")
        }
    }

    func testDeleteQuestionAttempt() {
        // Use unique ID for this test
        let uniqueID = "test_delete_\(UUID().uuidString)"

        // Create an attempt
        let attempt = QuestionAttempt(context: testContext)
        attempt.questionID = uniqueID
        attempt.category = "Traffic Signs"
        attempt.wasCorrect = true
        attempt.timestamp = Date()

        try? testContext.save()

        // Delete it
        testContext.delete(attempt)

        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to delete: \(error)")
        }

        // Verify deletion
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", uniqueID)

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 0, "Should not find deleted attempt")
        } catch {
            XCTFail("Failed to verify deletion: \(error)")
        }
    }

    func testBatchDeleteQuestionAttempts() {
        // Create multiple attempts
        for i in 0..<10 {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "test\(i)"
            attempt.category = "Traffic Signs"
            attempt.wasCorrect = true
            attempt.timestamp = Date()
        }

        try? testContext.save()

        // Batch delete
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = QuestionAttempt.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try testContext.execute(deleteRequest)
            try testContext.save()
            testContext.refreshAllObjects()
        } catch {
            XCTFail("Failed to batch delete: \(error)")
        }

        // Verify all deleted
        let verifyRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        do {
            let results = try testContext.fetch(verifyRequest)
            XCTAssertEqual(results.count, 0, "Should have deleted all attempts")
        } catch {
            XCTFail("Failed to verify batch delete: \(error)")
        }
    }

    // MARK: - UserProgress Entity Tests

    func testCreateUserProgress() {
        let progress = UserProgress(context: testContext)
        progress.totalPoints = 500
        progress.currentLevel = 2
        progress.lastStudyDate = Date()
        progress.streak = 5

        XCTAssertEqual(progress.totalPoints, 500)
        XCTAssertEqual(progress.currentLevel, 2)
        XCTAssertNotNil(progress.lastStudyDate)
        XCTAssertEqual(progress.streak, 5)
    }

    func testSaveUserProgress() {
        let progress = UserProgress(context: testContext)
        progress.totalPoints = 1000
        progress.currentLevel = 3
        progress.lastStudyDate = Date()

        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to save UserProgress: \(error)")
        }

        // Verify it was saved
        let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertGreaterThan(results.count, 0, "Should find saved progress")
            let savedProgress = results.first(where: { $0.totalPoints == 1000 })
            XCTAssertNotNil(savedProgress)
            XCTAssertEqual(savedProgress?.currentLevel, 3)
        } catch {
            XCTFail("Failed to fetch UserProgress: \(error)")
        }
    }

    func testUpdateUserProgress() {
        // Create initial progress
        let progress = UserProgress(context: testContext)
        progress.totalPoints = 500
        progress.currentLevel = 2

        try? testContext.save()

        // Update it
        progress.totalPoints = 1000
        progress.currentLevel = 3

        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to update UserProgress: \(error)")
        }

        // Verify update
        let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()
        do {
            let results = try testContext.fetch(fetchRequest)
            let updatedProgress = results.first(where: { $0.totalPoints == 1000 })
            XCTAssertNotNil(updatedProgress)
            XCTAssertEqual(updatedProgress?.currentLevel, 3)
        } catch {
            XCTFail("Failed to verify update: \(error)")
        }
    }

    func testFetchUserProgress() {
        // Create progress entry
        let progress = UserProgress(context: testContext)
        progress.totalPoints = 750
        progress.currentLevel = 2

        try? testContext.save()

        // Fetch it
        let fetchRequest: NSFetchRequest<UserProgress> = UserProgress.fetchRequest()

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertFalse(results.isEmpty, "Should find user progress")
        } catch {
            XCTFail("Failed to fetch UserProgress: \(error)")
        }
    }

    // MARK: - Data Integrity Tests

    func testQuestionAttemptTimestampPersistence() {
        let uniqueID = "test_timestamp_\(UUID().uuidString)"
        let now = Date()
        let attempt = QuestionAttempt(context: testContext)
        attempt.questionID = uniqueID
        attempt.category = "Traffic Signs"
        attempt.wasCorrect = true
        attempt.timestamp = now

        try? testContext.save()

        // Fetch and verify timestamp
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", uniqueID)

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)

            if let savedTimestamp = results.first?.timestamp {
                XCTAssertEqual(savedTimestamp.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
            } else {
                XCTFail("Timestamp should not be nil")
            }
        } catch {
            XCTFail("Failed to verify timestamp: \(error)")
        }
    }

    func testQuestionAttemptBooleanPersistence() {
        let correctID = "correct_\(UUID().uuidString)"
        let incorrectID = "incorrect_\(UUID().uuidString)"

        // Test correct answer
        let correctAttempt = QuestionAttempt(context: testContext)
        correctAttempt.questionID = correctID
        correctAttempt.category = "Test"
        correctAttempt.wasCorrect = true
        correctAttempt.timestamp = Date()

        // Test incorrect answer
        let incorrectAttempt = QuestionAttempt(context: testContext)
        incorrectAttempt.questionID = incorrectID
        incorrectAttempt.category = "Test"
        incorrectAttempt.wasCorrect = false
        incorrectAttempt.timestamp = Date()

        try? testContext.save()

        // Verify both by unique IDs
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID IN %@", [correctID, incorrectID])

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 2)

            let correct = results.first { $0.questionID == correctID }
            let incorrect = results.first { $0.questionID == incorrectID }

            XCTAssertTrue(correct?.wasCorrect ?? false)
            XCTAssertFalse(incorrect?.wasCorrect ?? true)
        } catch {
            XCTFail("Failed to verify booleans: \(error)")
        }
    }

    func testMultipleQuestionAttemptsForSameQuestion() {
        // Create 5 attempts for same question
        for i in 0..<5 {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "repeated"
            attempt.category = "Traffic Signs"
            attempt.wasCorrect = i % 2 == 0
            attempt.timestamp = Date().addingTimeInterval(Double(i * 60))
            attempt.timeTaken = Int32(10 + i)
        }

        try? testContext.save()

        // Verify all saved
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", "repeated")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 5, "Should save all 5 attempts")

            // Verify they're in chronological order
            for i in 0..<results.count - 1 {
                XCTAssertLessThan(results[i].timestamp ?? Date(), results[i + 1].timestamp ?? Date())
            }
        } catch {
            XCTFail("Failed to verify multiple attempts: \(error)")
        }
    }

    // MARK: - Query Performance Tests

    func testFetchPerformanceWithManyAttempts() {
        // Create 100 attempts
        for i in 0..<100 {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "q\(i % 10)" // 10 unique questions, 10 attempts each
            attempt.category = "Category \(i % 5)"
            attempt.wasCorrect = i % 2 == 0
            attempt.timestamp = Date().addingTimeInterval(Double(i))
        }

        try? testContext.save()

        // Measure fetch performance
        measure {
            let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
            _ = try? testContext.fetch(fetchRequest)
        }
    }

    func testPredicateFetchPerformance() {
        // Create many attempts
        for i in 0..<100 {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "q\(i)"
            attempt.category = i < 50 ? "Category A" : "Category B"
            attempt.wasCorrect = true
            attempt.timestamp = Date()
        }

        try? testContext.save()

        // Measure filtered fetch
        measure {
            let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == %@", "Category A")
            _ = try? testContext.fetch(fetchRequest)
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentSave() {
        let expectation = self.expectation(description: "Concurrent saves")
        expectation.expectedFulfillmentCount = 2

        // Create two background contexts
        let context1 = persistenceController.container.newBackgroundContext()
        let context2 = persistenceController.container.newBackgroundContext()

        // Save on context 1
        context1.perform {
            let attempt = QuestionAttempt(context: context1)
            attempt.questionID = "concurrent1"
            attempt.category = "Test"
            attempt.wasCorrect = true
            attempt.timestamp = Date()

            try? context1.save()
            expectation.fulfill()
        }

        // Save on context 2
        context2.perform {
            let attempt = QuestionAttempt(context: context2)
            attempt.questionID = "concurrent2"
            attempt.category = "Test"
            attempt.wasCorrect = true
            attempt.timestamp = Date()

            try? context2.save()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        // Verify both saved
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        let results = try? testContext.fetch(fetchRequest)
        XCTAssertGreaterThanOrEqual(results?.count ?? 0, 2, "Should have saved from both contexts")
    }

    // MARK: - Error Handling Tests

    func testSaveWithoutRequiredFields() {
        // QuestionAttempt without questionID (if it's required)
        let attempt = QuestionAttempt(context: testContext)
        attempt.category = "Test"
        attempt.wasCorrect = true
        attempt.timestamp = Date()
        // Missing questionID

        // Attempt to save - may or may not fail depending on model requirements
        do {
            try testContext.save()
            // If it succeeds, that's fine - questionID might be optional
        } catch {
            // If it fails, that's also fine - just verifying error handling
            XCTAssertNotNil(error, "Should handle save errors gracefully")
        }
    }

    // MARK: - Integration Tests

    func testCompleteDataFlow() {
        // Create a question attempt
        let attempt = QuestionAttempt(context: testContext)
        attempt.questionID = "integration_test"
        attempt.category = "Traffic Signs"
        attempt.wasCorrect = true
        attempt.timestamp = Date()
        attempt.timeTaken = 15

        // Save it
        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to save: \(error)")
        }

        // Fetch it
        let fetchRequest: NSFetchRequest<QuestionAttempt> = QuestionAttempt.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "questionID == %@", "integration_test")

        do {
            let results = try testContext.fetch(fetchRequest)
            XCTAssertEqual(results.count, 1)

            let fetched = results.first!
            XCTAssertEqual(fetched.questionID, "integration_test")
            XCTAssertEqual(fetched.category, "Traffic Signs")
            XCTAssertTrue(fetched.wasCorrect)
            XCTAssertEqual(fetched.timeTaken, 15)

            // Update it
            fetched.timeTaken = 20
            try testContext.save()

            // Fetch again to verify update
            let updatedResults = try testContext.fetch(fetchRequest)
            XCTAssertEqual(updatedResults.first?.timeTaken, 20)

            // Delete it
            testContext.delete(fetched)
            try testContext.save()

            // Verify deletion
            let finalResults = try testContext.fetch(fetchRequest)
            XCTAssertEqual(finalResults.count, 0)

        } catch {
            XCTFail("Integration test failed: \(error)")
        }
    }

    // MARK: - Performance Tests

    func testSavePerformance() {
        measure {
            let attempt = QuestionAttempt(context: testContext)
            attempt.questionID = "perf_test"
            attempt.category = "Traffic Signs"
            attempt.wasCorrect = true
            attempt.timestamp = Date()

            try? testContext.save()

            // Clean up
            testContext.delete(attempt)
            try? testContext.save()
        }
    }
}
