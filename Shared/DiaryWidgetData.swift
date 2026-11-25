import Foundation

enum MacroFocus: String, Codable, CaseIterable {
    case balanced, strength, endurance

    var proteinPerPound: Double { self == .strength ? 0.8 : 0.7 }

    var title: String {
        switch self {
        case .balanced: return "Everyday balance"
        case .strength: return "Keep or build muscle"
        case .endurance: return "Fuel endurance training"
        }
    }

    var formula: String {
        switch self {
        case .balanced: return "0.7 g of protein and 0.5 g of fat per pound of body weight."
        case .strength: return "0.8 g of protein and 0.5 g of fat per pound of body weight."
        case .endurance: return "0.7 g of protein per pound of body weight and 30% of daily calories from fat."
        }
    }
}

enum DailyCalorieBudget {
    static func intake(maintenance: Double?, multiplier: Double, fixedDeficit: Double?) -> Double? {
        guard let maintenance, maintenance.isFinite, maintenance > 0 else { return nil }
        let goal = fixedDeficit.map { maintenance - $0 } ?? (maintenance * multiplier)
        return goal.isFinite && goal > 0 ? goal : nil
    }
}

struct MacroOverrides: Codable, Equatable {
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var isEmpty: Bool { protein == nil && carbs == nil && fat == nil }
}

struct DailyMacroTargets {
    let protein: Double?
    let fat: Double?
    let carbs: Double?

    init(weightPounds: Double?, calorieGoal: Double, focus: MacroFocus = .balanced, overrides: MacroOverrides? = nil) {
        let weight = weightPounds.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        protein = overrides?.protein ?? weight.map { $0 * focus.proteinPerPound }
        fat = overrides?.fat ?? (focus == .endurance
            ? (calorieGoal > 0 ? calorieGoal * 0.30 / 9 : nil)
            : weight.map { $0 * 0.5 })
        if let manual = overrides?.carbs { carbs = manual }
        else if let protein, let fat, calorieGoal > 0 {
            carbs = Self.carbohydrateTarget(calorieGoal: calorieGoal, protein: protein, fat: fat)
        } else {
            carbs = nil
        }
    }

    static func carbohydrateTarget(calorieGoal: Double, protein: Double, fat: Double) -> Double? {
        let remaining = calorieGoal - (protein * 4 + fat * 9)
        return remaining >= 0 ? remaining / 4 : nil
    }
}

struct DiaryWidgetData: Codable, Equatable {
    let day: Date
    let maintenance: Double?
    let calories, carbs, protein, fat: Double
    var proteinTarget, fatTarget: Double?
    var multiplier: Double
    // Build 22 stored targets using the balanced formula.
    var focus: MacroFocus? = nil

    var weightPounds: Double? = nil
    var overrides: MacroOverrides? = nil

    var fixedDeficit: Double? = nil

    mutating func apply(multiplier: Double, focus: MacroFocus, overrides: MacroOverrides? = nil, fixedDeficit: Double? = nil) {
        self.fixedDeficit = fixedDeficit
        let weight = weightPounds ?? (self.overrides?.protein == nil ? proteinTarget.map { $0 / (self.focus ?? .balanced).proteinPerPound } : nil)
        self.weightPounds = weight
        self.overrides = overrides
        self.multiplier = multiplier
        self.focus = focus
        let targets = DailyMacroTargets(weightPounds: weight, calorieGoal: calorieGoal ?? 0, focus: focus, overrides: overrides)
        proteinTarget = targets.protein
        fatTarget = targets.fat
    }

    var balance: Double? { maintenance.map { $0 - calories } }
    private var plannedIntake: Double? {
        DailyCalorieBudget.intake(maintenance: maintenance, multiplier: multiplier, fixedDeficit: fixedDeficit)
    }
    var targetBalance: Double? { plannedIntake.flatMap { intake in maintenance.map { $0 - intake } } }
    var calorieGoal: Double? { plannedIntake?.rounded() }
    var carbTarget: Double? {
        if let manual = overrides?.carbs { return manual }
        guard let calorieGoal, let proteinTarget, let fatTarget else { return nil }
        return DailyMacroTargets.carbohydrateTarget(calorieGoal: calorieGoal, protein: proteinTarget, fat: fatTarget)
    }
}

enum DiaryShortcut: String {
    case today, barcode, plate, quickAdd = "quick-add"

    var url: URL { URL(string: "dietic://" + rawValue)! }
    init?(url: URL) {
        guard url.scheme?.lowercased() == "dietic", let host = url.host, url.path.isEmpty else { return nil }
        self.init(rawValue: host.lowercased())
    }
}

struct DiaryWidgetRecord: Codable {
    static let kind = "DieticDailyBalance"
    static let diaryURL = URL(string: "dietic://today")!
    let updated: Date
    let data: DiaryWidgetData

    private static var file: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.co.yotzin.Dietic")?
            .appendingPathComponent("today.json")
    }

    static func today(at date: Date = .now) -> Self? {
        guard let file, let bytes = try? Data(contentsOf: file),
              let record = try? JSONDecoder().decode(Self.self, from: bytes),
              record.data.day == Calendar.current.startOfDay(for: date) else { return nil }
        return record
    }

    static func save(_ data: DiaryWidgetData) throws -> Bool {
        guard let file else { throw CocoaError(.fileNoSuchFile) }
        guard data.day == Calendar.current.startOfDay(for: .now), today()?.data != data else { return false }
        let bytes = try JSONEncoder().encode(Self(updated: .now, data: data))
        try bytes.write(to: file, options: [.atomic, .completeFileProtection])
        return true
    }
}
