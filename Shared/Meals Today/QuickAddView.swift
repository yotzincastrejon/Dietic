import SwiftUI

struct QuickAddView: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var meal = EatingTime.current
    @State private var saving = false
    @State private var error: String?

    private var nutrients: [Int: Double]? {
        var values: [Int: Double] = [:]
        for (id, text) in [(208, calories), (203, protein), (205, carbs), (204, fat)] {
            let raw = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.isEmpty, id != 208 { continue }
            guard let amount = PortionInput.decimal(raw),
                  amount.isFinite, (0...1_000_000).contains(amount) else { return nil }
            values[id] = amount
        }
        return values
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Food name (optional)", text: $name)
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description) }
                    }
                }
                Section {
                    field("Calories", unit: "kcal", text: $calories)
                } header: { Text("Amount eaten") }
                Section("Macros (optional)") {
                    field("Protein", unit: "g", text: $protein)
                    field("Carbs", unit: "g", text: $carbs)
                    field("Fat", unit: "g", text: $fat)
                }
                if let error { Text(error).foregroundStyle(WarmInk.action) }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                Button(saving ? "Logging…" : "Log to " + meal.description.lowercased()) {
                    guard !saving, let nutrients else { return }
                    saving = true
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let food = SavedFood(name: trimmed.isEmpty ? "Quick add" : trimmed, brand: nil,
                                         servingQuantity: 1, servingUnit: "portion", servingGrams: nil, nutrients: nutrients)
                    let sample = food.sample(multiplier: 1, quantity: 1, unit: .serving, meal: meal, date: manager.mealTimestamp)
                    Task {
                        defer { saving = false }
                        do { try await manager.saveMeal(sample); dismiss() }
                        catch { self.error = error.localizedDescription }
                    }
                }.buttonStyle(JournalActionStyle()).disabled(saving || nutrients == nil)
                .padding(.horizontal).padding(.vertical, 8).background(WarmInk.paper)
            }
            .navigationTitle("Quick add")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .disabled(saving)
        }.preferredColorScheme(.light).tint(WarmInk.action).interactiveDismissDisabled(saving)
    }

    private func field(_ title: String, unit: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            TextField("Amount", text: text).accessibilityLabel(title)
                .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}
