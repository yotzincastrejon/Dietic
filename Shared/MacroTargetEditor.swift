import SwiftUI

struct MacroTargetEditor: View {
    let plan: NutritionPlan
    let energy: DailyEnergy
    let save: (NutritionPlan) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String

    init(plan: NutritionPlan, energy: DailyEnergy, save: @escaping (NutritionPlan) -> Void) {
        self.plan = plan
        self.energy = energy
        self.save = save
        func text(_ amount: Double?) -> String {
            amount.map { $0.formatted(.number.grouping(.never)) } ?? ""
        }
        _protein = State(initialValue: text(plan.overrides?.protein))
        _carbs = State(initialValue: text(plan.overrides?.carbs))
        _fat = State(initialValue: text(plan.overrides?.fat))
    }

    private func grams(_ text: String) -> Double? {
        guard let value = PortionInput.decimal(text), value.isFinite,
              (0.1...10_000).contains(value) else { return nil }
        return value
    }

    private var updated: NutritionPlan? {
        guard [protein, carbs, fat].allSatisfy({ $0.isEmpty || grams($0) != nil }) else { return nil }
        let custom = MacroOverrides(protein: grams(protein), carbs: grams(carbs), fat: grams(fat))
        var result = plan
        result.overrides = custom.isEmpty ? nil : custom
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    row("Protein", value: $protein)
                    row("Carbs", value: $carbs)
                    row("Fat", value: $fat)
                } header: { Text("Daily targets in grams") } footer: { Text("Leave a field empty to use your plan. Automatic carbs use the calories remaining after protein and fat.") }
                if let updated {
                    let targets = updated.targets(for: energy)
                    Section("Your targets") {
                        summary("Protein", targets.protein)
                        summary("Carbs", targets.carbs)
                        summary("Fat", targets.fat)
                    }
                }
                Button("Use plan for all three") { protein = ""; carbs = ""; fat = "" }
            }
            .navigationTitle("Macro targets")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { if let updated { save(updated) } }.disabled(updated == nil) }
            }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }

    private func row(_ title: String, value: Binding<String>) -> some View {
        HStack {
            Text(title)
            TextField("Automatic", text: value).keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing).accessibilityLabel(title + " target")
        }
    }

    private func summary(_ title: String, _ amount: Double?) -> some View {
        LabeledContent(title, value: amount.map { $0.formatted(.number.precision(.fractionLength(0...1))) + " g" } ?? "Unavailable")
    }
}
