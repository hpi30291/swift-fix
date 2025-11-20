import XCTest
@testable import CADMVPermitPrep

final class LearnManagerTests: XCTestCase {

    var learnManager: LearnManager!

    override func setUp() {
        super.setUp()
        learnManager = LearnManager.shared
    }

    override func tearDown() {
        learnManager = nil
        super.tearDown()
    }

    func testModulesLoaded() {
        // Trigger module loading
        _ = learnManager.totalLessons

        XCTAssertFalse(learnManager.modules.isEmpty, "Modules should be loaded")
        XCTAssertEqual(learnManager.modules.count, 8, "Should have 8 modules")
    }

    func testTotalLessonsCount() {
        let totalLessons = learnManager.totalLessons
        XCTAssertGreaterThan(totalLessons, 0, "Should have lessons")
    }

    func testCompletedCount() {
        // Should not crash with no data
        let count = learnManager.completedCount(for: "module_1")
        XCTAssertGreaterThanOrEqual(count, 0, "Completed count should be non-negative")
    }

    func testProgress() {
        // Should return value between 0 and 1
        let progress = learnManager.progress(for: "module_1")
        XCTAssertGreaterThanOrEqual(progress, 0.0, "Progress should be >= 0")
        XCTAssertLessThanOrEqual(progress, 1.0, "Progress should be <= 1")
    }
}
