import Foundation
import Combine

/// Manages Learn Mode modules, lessons, and progress tracking
class LearnManager: ObservableObject {
    static let shared = LearnManager()

    @Published var modules: [Module] = []
    @Published var completedLessons: Set<String> = [] // "moduleId_lessonNumber"

    private let completedLessonsKey = "completedLessons"
    private var isLoaded = false

    private init() {
        loadCompletedLessons()
        // Don't load modules at init - lazy load when first accessed
        // This speeds up app launch
    }

    // MARK: - Load Modules

    private func loadModules() {
        // Only load once
        guard !isLoaded else { return }
        isLoaded = true

        var loadedModules: [Module] = []

        // Load all 8 modules
        if let m1 = loadModuleFromFile("module 1 traffic_signs_module") {
            loadedModules.append(m1)
        }
        if let m2 = loadModuleFromFile("module 2 traffic_laws_module") {
            loadedModules.append(m2)
        }
        if let m3 = loadModuleFromFile("module 3 defensive_driving_module") {
            loadedModules.append(m3)
        }
        if let m4 = loadModuleFromFile("module 4 sharing_road_module") {
            loadedModules.append(m4)
        }
        if let m5 = loadModuleFromFile("module 5 right_of_way_module") {
            loadedModules.append(m5)
        }
        if let m6 = loadModuleFromFile("module 6 parking_stopping_module") {
            loadedModules.append(m6)
        }
        if let m7 = loadModuleFromFile("module 7 alcohol_drugs") {
            loadedModules.append(m7)
        }
        if let m8 = loadModuleFromFile("module 8 special_situations") {
            loadedModules.append(m8)
        }

        if loadedModules.count < 8 {
            loadedModules = defaultModules()
        }
        modules = loadedModules
        #if DEBUG
        print("✅ Loaded \(modules.count) Learn Mode modules with \(totalLessons) total lessons")
        #endif
    }

    private func loadModuleFromFile(_ filename: String) -> Module? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            #if DEBUG
            print("❌ Could not find \(filename).json")
            #endif
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let module = try JSONDecoder().decode(Module.self, from: data)
            #if DEBUG
            print("✅ Loaded module: \(module.moduleName) with \(module.lessons.count) lessons")
            #endif
            return module
        } catch {
            #if DEBUG
            print("❌ Error loading \(filename): \(error)")
            #endif
            return nil
        }
    }

    private func defaultModules() -> [Module] {
        let categories: [QuestionCategory] = QuestionCategory.allCases
        let colors: [QuestionCategory: String] = [
            .trafficSigns: "#F59E0B",
            .trafficLaws: "#3B82F6",
            .defensiveDriving: "#10B981",
            .sharingTheRoad: "#8B5CF6",
            .rightOfWay: "#8B5CF6",
            .parking: "#6B7280",
            .alcoholAndDrugs: "#EF4444",
            .specialSituations: "#22C55E"
        ]

        return categories.map { category in
            let lesson = Lesson(
                lessonNumber: 1,
                title: "Overview",
                icon: category.icon,
                overview: "",
                keyPoints: [""],
                detailedContent: "",
                example: "",
                memoryTip: "",
                images: [],
                estimatedReadTime: 1
            )
            return Module(
                moduleId: category.moduleId,
                moduleName: category.displayName,
                icon: category.icon,
                color: colors[category] ?? "#3B82F6",
                lessons: [lesson]
            )
        }
    }

    // MARK: - Progress Tracking

    /// Mark a lesson as completed
    func markLessonCompleted(moduleId: String, lessonNumber: Int) {
        let key = "\(moduleId)_\(lessonNumber)"
        completedLessons.insert(key)
        saveCompletedLessons()

        // Track event
        EventTracker.shared.trackEvent(
            name: "lesson_completed",
            parameters: [
                "module_id": moduleId,
                "lesson_number": lessonNumber
            ]
        )
    }

    /// Check if a lesson is completed
    func isLessonCompleted(moduleId: String, lessonNumber: Int) -> Bool {
        let key = "\(moduleId)_\(lessonNumber)"
        return completedLessons.contains(key)
    }

    /// Get number of completed lessons for a module
    func completedCount(for moduleId: String) -> Int {
        let completed = completedLessons.filter { $0.hasPrefix(moduleId + "_") }.count
        return completed
    }

    /// Get progress percentage for a module (0.0 to 1.0)
    func progress(for moduleId: String) -> Double {
        loadModules() // Ensure modules are loaded
        guard let module = modules.first(where: { $0.moduleId == moduleId }) else {
            return 0
        }

        let completed = completedCount(for: moduleId)
        guard module.totalLessons > 0 else { return 0 }

        return Double(completed) / Double(module.totalLessons)
    }

    /// Get next incomplete lesson for a module
    func nextLesson(for moduleId: String) -> Lesson? {
        loadModules() // Ensure modules are loaded
        guard let module = modules.first(where: { $0.moduleId == moduleId }) else {
            return nil
        }

        // Find first incomplete lesson
        for lesson in module.lessons {
            if !isLessonCompleted(moduleId: moduleId, lessonNumber: lesson.lessonNumber) {
                return lesson
            }
        }

        // All lessons completed, return first one
        return module.lessons.first
    }

    // MARK: - Persistence

    private func loadCompletedLessons() {
        if let saved = UserDefaults.standard.array(forKey: completedLessonsKey) as? [String] {
            completedLessons = Set(saved)
        }
    }

    private func saveCompletedLessons() {
        UserDefaults.standard.set(Array(completedLessons), forKey: completedLessonsKey)
    }

    // MARK: - Computed Properties

    var totalLessons: Int {
        loadModules() // Ensure modules are loaded
        return modules.reduce(0) { $0 + $1.totalLessons }
    }

    var totalCompletedLessons: Int {
        completedLessons.count
    }

    var overallProgress: Double {
        guard totalLessons > 0 else { return 0 }
        return Double(totalCompletedLessons) / Double(totalLessons)
    }

    // MARK: - Reset (for testing)

    #if DEBUG
    func resetProgress() {
        completedLessons.removeAll()
        saveCompletedLessons()
    }
    #endif
}
