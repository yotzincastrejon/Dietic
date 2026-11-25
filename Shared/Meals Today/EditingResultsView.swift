import SwiftUI

struct EditingResultsView: View {
    @ObservedObject var fastingManager: FastingManager
    let sample: HKSampleWithDescription
    @Environment(\.dismiss) private var dismiss
    @State private var meal: EatingTime
    @State private var input: PortionInput
    @State private var saving = false
    @State private var date: Date
    @State private var changingTime = false
    @State private var operationID = UUID()
    @State private var errorMessage = ""
    @State private var showError = false

    init(fastingManager: FastingManager, sample: HKSampleWithDescription) {
        self.fastingManager = fastingManager
        self.sample = sample
        _date = State(initialValue: min(.now, sample.date))
        _meal = State(initialValue: EatingTime.allCases.first { $0.description == sample.mealPeriod } ?? .breakfast)
        _input = State(initialValue: PortionInput(portion: sample.portion, savedQuantity: sample.numberOfServings,
                                                  savedAsGrams: sample.servingSelection == ServingType.gram.description))
    }

    private var multiplier: Double? {
        guard sample.numberOfServings > 0 else { return nil }
        if sample.servingSelection == ServingType.gram.description {
            if input.unit == .grams { return input.quantity.map { $0 / sample.numberOfServings } }
            guard sample.servingWeightGrams > 0 else { return nil }
            return input.servings.map { $0 * (input.portion.grams ?? 0) / sample.numberOfServings }
        }
        guard let scale = input.portion.scale(relativeTo: sample.portion) else { return nil }
        return input.servings.map { $0 * scale / sample.numberOfServings }
    }

    var body: some View {
        ServingPage(name: sample.foodName, meal: $meal, input: $input,
                    calories: amount(sample.calories), carbs: nutrient(205, sample.totalCarbohydrate),
                    protein: nutrient(203, sample.protein), fat: nutrient(204, sample.totalFat),
                    actionTitle: saving ? "Saving…" : "Save changes", canSave: multiplier != nil && !saving, save: {
            guard !saving, let quantity = input.savedQuantity, let multiplier else { return }
            saving = true
            Task { await save(quantity: quantity, multiplier: multiplier) }
        }, preserveAmountOnSetup: true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .primaryAction) {
                Button { changingTime = true } label: { Label("Edit date and time", systemImage: "calendar.badge.clock") }
            }
        }
        .sheet(isPresented: $changingTime) {
            NavigationStack {
                Form { DatePicker("Logged at", selection: $date, in: ...Date.now) }
                    .navigationTitle("Entry date and time")
                    .toolbar { Button("Done") { changingTime = false } }
            }.presentationDetents([.medium]).preferredColorScheme(.light).tint(WarmInk.action)
        }
        .disabled(saving)
        .interactiveDismissDisabled(saving)
        .alert("Couldn’t save meal", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
    }

    private func nutrient(_ id: Int, _ value: Double) -> String {
        sample.attrIDArray.contains(id) ? amount(value) : "—"
    }

    private func amount(_ original: Double) -> String {
        (original * (multiplier ?? 0)).formatted(.number.precision(.fractionLength(0...1)))
    }

    @MainActor private func save(quantity: Double, multiplier: Double) async {
        defer { saving = false }
        var replacement = sample
        for nutrient in HKSampleWithDescription.nutrientFields.values { replacement[keyPath: nutrient] *= multiplier }
        replacement.servingQuantity = input.portion.quantity
        replacement.servingUnit = input.portion.unit
        replacement.servingWeightGrams = input.portion.grams ?? 0
        replacement.householdServing = input.portion.household
        replacement.numberOfServings = quantity
        replacement.mealPeriod = meal.description
        replacement.servingSelection = input.savedUnit.description
        replacement.date = date
        replacement.uuid = UUID().uuidString
        do {
            try await fastingManager.editEntry(sample, replacing: replacement, operationID: operationID)
            fastingManager.selectDay(date)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
