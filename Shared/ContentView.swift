import SwiftUI

struct NutritionPlan: Codable, Equatable {
    var goal: DietGoal
    var level: DietDeficitLevel
    var focus: MacroFocus
    var overrides: MacroOverrides? = nil
    var fixedDeficit: Double? = nil

    var selectedFixedDeficit: Double? { goal == .deficit ? fixedDeficit : nil }

    static func legacy(_ defaults: UserDefaults = .standard) -> Self {
        Self(goal: DietGoal(rawValue: defaults.string(forKey: "dietGoal") ?? "") ?? .maintaining,
             level: DietDeficitLevel(rawValue: defaults.string(forKey: "deficitLevel") ?? "") ?? .normal,
             focus: .balanced)
    }

    var multiplier: Double { goal.multiplier(for: level) }

    func calorieGoal(for energy: DailyEnergy) -> Int? {
        DailyCalorieBudget.intake(maintenance: energy.estimatedMaintenance, multiplier: multiplier,
                                 fixedDeficit: selectedFixedDeficit).map { Int($0.rounded()) }
    }

    func targetBalance(for energy: DailyEnergy) -> Double? {
        guard let maintenance = energy.estimatedMaintenance,
              let intake = DailyCalorieBudget.intake(maintenance: maintenance, multiplier: multiplier, fixedDeficit: selectedFixedDeficit) else { return nil }
        return maintenance - intake
    }

    func targets(for energy: DailyEnergy) -> DailyMacroTargets {
        DailyMacroTargets(weightPounds: energy.recordedWeightPounds, calorieGoal: Double(calorieGoal(for: energy) ?? 0), focus: focus, overrides: overrides)
    }
}

struct ContentView: View {
    @ObservedObject var fastingManager: FastingManager
    @AppStorage("nutritionPlan.v1") private var savedPlan = Data()
    @Environment(\.scenePhase) private var scenePhase
    @State private var previewRequested = false
    @State private var incoming: SharedMeal?
    @StateObject private var intentRouter = DiaryIntentRouter.shared
    @State private var choosingFile = false
    @State private var importError: String?

    private var plan: NutritionPlan? { try? JSONDecoder().decode(NutritionPlan.self, from: savedPlan) }
    private var diaryActive: Bool { scenePhase == .active && (plan != nil || previewRequested) }

    var body: some View {
        Group {
            if let plan {
                Home(fastingManager: fastingManager, plan: plan, savePlan: save, incoming: $incoming, shortcut: $intentRouter.destination, chooseMealFile: { choosingFile = true })
            } else {
                let existing = NutritionPlan.legacy()
                WelcomeView(plan: existing, energy: fastingManager.dailyEnergy,
                            onReview: { previewRequested = true }, save: save,
                            closeTitle: "Skip", close: { save(existing) })
            }
        }
        .onOpenURL { url in
            if url.isFileURL { openMeal(url) }
            else if let target = DiaryShortcut(url: url) { intentRouter.destination = target }
        }
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.dieticMeal]) { result in
            do { openMeal(try result.get()) }
            catch { if (error as NSError).code != NSUserCancelledError { importError = error.localizedDescription } }
        }
        .alert("Couldn’t open meal", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK") { importError = nil }
        } message: { Text(importError ?? "") }
        .onAppear {
            fastingManager.applyPlan(plan ?? .legacy())
            fastingManager.setDiaryActive(diaryActive)
        }
        .onChange(of: diaryActive) { active in fastingManager.setDiaryActive(active) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            fastingManager.calendarChanged()
        }
    }

    private func openMeal(_ url: URL) {
        do { incoming = try SharedMeal.read(url) }
        catch { importError = error.localizedDescription }
    }

    private func save(_ selection: NutritionPlan) {
        guard let encoded = try? JSONEncoder().encode(selection) else { return }
        savedPlan = encoded
        fastingManager.applyPlan(selection)
    }
}
