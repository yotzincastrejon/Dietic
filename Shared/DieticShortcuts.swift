import AppIntents
import Combine
import HealthKit

@MainActor
final class DiaryIntentRouter: ObservableObject {
    static let shared = DiaryIntentRouter()
    @Published var destination: DiaryShortcut?
}

struct ScanGroceryIntent: AppIntent {
    static let title: LocalizedStringResource = "Scan a grocery barcode"
    static let description = IntentDescription("Open Dietic’s barcode scanner.")
    static let openAppWhenRun = true
    @available(iOS 26.0, *) static var supportedModes: IntentModes { .foreground }
    @MainActor func perform() async throws -> some IntentResult {
        DiaryIntentRouter.shared.destination = .barcode
        return .result()
    }
}

struct ScanPlateIntent: AppIntent {
    static let title: LocalizedStringResource = "Scan a plate"
    static let description = IntentDescription("Photograph a meal and review the foods and portions in Dietic.")
    static let openAppWhenRun = true
    @available(iOS 26.0, *) static var supportedModes: IntentModes { .foreground }
    @MainActor func perform() async throws -> some IntentResult {
        DiaryIntentRouter.shared.destination = .plate
        return .result()
    }
}

struct QuickFoodIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick add food"
    static let description = IntentDescription("Enter calories and optional macros for a food.")
    static let openAppWhenRun = true
    @available(iOS 26.0, *) static var supportedModes: IntentModes { .foreground }
    @MainActor func perform() async throws -> some IntentResult {
        DiaryIntentRouter.shared.destination = .quickAdd
        return .result()
    }
}

struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log water"
    static let description = IntentDescription("Record a drink in Apple Health after granting water access in Dietic.")
    @Parameter(title: "Amount") var amount: Double
    @Parameter(title: "Unit", default: .milliliters) var unit: WaterUnit
    static var parameterSummary: some ParameterSummary { Summary("Log \(\.$amount) \(\.$unit) of water") }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount.isFinite, amount > 0 else { return .result(dialog: "Enter an amount greater than zero.") }
        let store = HKHealthStore()
        guard store.authorizationStatus(for: HKQuantityType(.dietaryWater)) == .sharingAuthorized else {
            return .result(dialog: "Open Water in Dietic and allow water logging in Health first.")
        }
        try await DieticWater.save(amount, unit: unit, at: .now, in: store)
        return .result(dialog: "Logged \(amount.formatted()) \(unit.rawValue) of water.")
    }
}

extension WaterUnit: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Water unit"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .milliliters: "Milliliters", .ounces: "US fluid ounces"
    ]
}

struct DieticShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ScanGroceryIntent(), phrases: ["Scan a barcode in \(.applicationName)"],
                    shortTitle: "Scan a barcode", systemImageName: "barcode.viewfinder")
        AppShortcut(intent: ScanPlateIntent(), phrases: ["Scan my plate with \(.applicationName)"],
                    shortTitle: "Scan my plate", systemImageName: "camera.viewfinder")
        AppShortcut(intent: QuickFoodIntent(), phrases: ["Quick add food in \(.applicationName)"],
                    shortTitle: "Quick add food", systemImageName: "bolt")
        AppShortcut(intent: LogWaterIntent(), phrases: ["Log water in \(.applicationName)"],
                    shortTitle: "Log water", systemImageName: "drop")
    }
}
