import Foundation

/// Single source of truth for all question categories in the app
/// This enum ensures consistency between:
/// - Question JSON files
/// - Learn Mode modules
/// - Quiz filtering
/// - Performance tracking
/// - Smart recommendations
enum QuestionCategory: String, CaseIterable {
    case trafficSigns = "Traffic Signs"
    case trafficLaws = "Traffic Laws"
    case defensiveDriving = "Defensive Driving"
    case sharingTheRoad = "Sharing the Road"
    case rightOfWay = "Right of Way"
    case parking = "Parking"
    case alcoholAndDrugs = "Alcohol & Drugs"
    case specialSituations = "Special Situations"

    // MARK: - Display Name

    /// The raw string value used in question JSON files
    var displayName: String {
        return self.rawValue
    }

    // MARK: - Module Mapping

    /// Maps category to corresponding Learn Mode module ID
    var moduleId: String {
        switch self {
        case .trafficSigns: return "traffic_signs"
        case .trafficLaws: return "traffic_laws"
        case .defensiveDriving: return "defensive_driving"
        case .sharingTheRoad: return "sharing_the_road"
        case .rightOfWay: return "right_of_way"
        case .parking: return "parking_stopping"
        case .alcoholAndDrugs: return "alcohol_drugs"
        case .specialSituations: return "special_situations"
        }
    }

    /// Maps module ID back to category
    static func fromModuleId(_ moduleId: String) -> QuestionCategory? {
        return QuestionCategory.allCases.first { $0.moduleId == moduleId }
    }

    /// Maps category string (from JSON) to enum case
    static func fromString(_ categoryString: String) -> QuestionCategory? {
        return QuestionCategory.allCases.first { $0.rawValue == categoryString }
    }

    // MARK: - UI Properties

    /// Icon for the category
    var icon: String {
        switch self {
        case .trafficSigns: return "triangle.fill"
        case .trafficLaws: return "book.fill"
        case .defensiveDriving: return "eye.fill"
        case .sharingTheRoad: return "person.3.fill"
        case .rightOfWay: return "arrow.triangle.swap"
        case .parking: return "parkingsign"
        case .alcoholAndDrugs: return "exclamationmark.triangle.fill"
        case .specialSituations: return "exclamationmark.circle.fill"
        }
    }

    // MARK: - All Categories

    /// Returns all category display names as an array
    static var allDisplayNames: [String] {
        return QuestionCategory.allCases.map { $0.displayName }
    }

    /// Returns all module IDs as an array
    static var allModuleIds: [String] {
        return QuestionCategory.allCases.map { $0.moduleId }
    }
}

// MARK: - Convenience Extensions

extension QuestionCategory: Identifiable {
    var id: String { return self.rawValue }
}

extension QuestionCategory: Comparable {
    static func < (lhs: QuestionCategory, rhs: QuestionCategory) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
