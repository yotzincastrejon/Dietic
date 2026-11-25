import SwiftUI

struct DiaryDayDetails: View {
    let date: Date
    let entries: [HKSampleWithDescription]
    @Environment(\.dismiss) private var dismiss
    @AppStorage private var note: String
    @AppStorage("nutrientTargets.v1") private var storedTargets = Data()
    @State private var editingTarget = false

    private var targets: [Int: DailyNutrientTarget] {
        (try? JSONDecoder().decode([Int: DailyNutrientTarget].self, from: storedTargets)) ?? [:]
    }

    init(date: Date, entries: [HKSampleWithDescription]) {
        self.date = date
        self.entries = entries
        _note = AppStorage(wrappedValue: "", JournalNoteRecord.key(for: date))
    }

    var body: some View {
        NavigationStack {
            List {
                if !targets.isEmpty {
                    Section("Daily nutrient targets") {
                        ForEach(Self.nutrients, id: \.id) { nutrient in
                            if let target = targets[nutrient.id], let path = HKSampleWithDescription.nutrientFields[nutrient.id] {
                                let known = entries.filter { $0.attrIDArray.contains(nutrient.id) }
                                let total = known.reduce(0) { $0 + $1[keyPath: path] }
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text(nutrient.name).font(.headline)
                                        Spacer()
                                        Text(target.display + " " + nutrient.format(target.amount)).font(.subheadline)
                                    }
                                    if !known.isEmpty {
                                        ProgressView(value: min(total, target.amount), total: target.amount).tint(WarmInk.action)
                                        Text(nutrient.format(total) + " recorded · " + "\(known.count) of \(entries.count) foods")
                                            .font(.caption).foregroundStyle(WarmInk.muted)
                                    } else { Text("No recorded amount").font(.caption).foregroundStyle(WarmInk.muted) }
                                }
                            }
                        }
                    }
                }
                Section("Journal note") {
                    TextField("Add a note about your day", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                    NavigationLink("All notes and backups") { JournalNotesView() }
                }
                Section {
                    ForEach(Self.nutrients, id: \.id) { nutrient in
                        if let path = HKSampleWithDescription.nutrientFields[nutrient.id] {
                            let known = entries.filter { $0.attrIDArray.contains(nutrient.id) }
                            let amount = known.reduce(0) { $0 + $1[keyPath: path] }
                            if known.isEmpty {
                                LabeledContent(nutrient.name, value: "—")
                            } else {
                                NavigationLink {
                                    List {
                                        Section("Total from logged foods") {
                                            LabeledContent(nutrient.name, value: nutrient.format(amount))
                                        }
                                        Section {
                                            ForEach(known.sorted { $0[keyPath: path] > $1[keyPath: path] }) { entry in
                                                HStack {
                                                    VStack(alignment: .leading) {
                                                        Text(entry.foodName)
                                                        Text(entry.mealPeriod).font(.caption).foregroundStyle(WarmInk.muted)
                                                    }
                                                    Spacer()
                                                    Text(nutrient.format(entry[keyPath: path])).monospacedDigit()
                                                }
                                            }
                                        } header: { Text("Food sources") }
                                          footer: { Text("\(known.count) of \(entries.count) logged foods include a value.") }
                                    }.navigationTitle(nutrient.name)
                                        .scrollContentBackground(.hidden).background(WarmInk.paper)
                                } label: {
                                    HStack {
                                        Text(nutrient.name)
                                        Spacer()
                                        VStack(alignment: .trailing) {
                                            Text(nutrient.format(amount))
                                            if known.count != entries.count {
                                                Text("\(known.count) of \(entries.count) foods").font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: { Text("Nutrients in your logged foods") }
                  footer: { Text("A dash means the foods have no recorded value for that nutrient.") }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle(date.formatted(.dateTime.month().day()))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Targets") { editingTarget = true } }
            }
            .sheet(isPresented: $editingTarget) {
                NutrientTargetsEditor(nutrients: Array(Self.nutrients.dropFirst(4)), existing: targets) { changed in
                    storedTargets = try JSONEncoder().encode(changed)
                }
            }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }

    fileprivate struct Nutrient {
        let id: Int, name: String, unit: String
        init(_ id: Int, _ name: String, _ unit: String) { self.id = id; self.name = name; self.unit = unit }
        func format(_ amount: Double) -> String {
            amount.formatted(.number.precision(.fractionLength(0...2))) + " " + unit
        }
    }

    private static let nutrients: [Nutrient] = [
        .init(208, "Calories", "kcal"), .init(203, "Protein", "g"), .init(205, "Carbohydrates", "g"),
        .init(204, "Fat", "g"), .init(291, "Fiber", "g"), .init(269, "Sugar", "g"),
        .init(606, "Saturated fat", "g"), .init(645, "Monounsaturated fat", "g"), .init(646, "Polyunsaturated fat", "g"),
        .init(601, "Cholesterol", "mg"), .init(307, "Sodium", "mg"), .init(301, "Calcium", "mg"),
        .init(303, "Iron", "mg"), .init(306, "Potassium", "mg"), .init(304, "Magnesium", "mg"),
        .init(305, "Phosphorus", "mg"), .init(309, "Zinc", "mg"), .init(312, "Copper", "mg"),
        .init(315, "Manganese", "mg"), .init(317, "Selenium", "µg"), .init(320, "Vitamin A", "µg"),
        .init(401, "Vitamin C", "mg"), .init(328, "Vitamin D", "µg"), .init(323, "Vitamin E", "mg"),
        .init(430, "Vitamin K", "µg"), .init(404, "Thiamin", "mg"), .init(405, "Riboflavin", "mg"),
        .init(406, "Niacin", "mg"), .init(415, "Vitamin B6", "mg"), .init(417, "Folate", "µg"),
        .init(418, "Vitamin B12", "µg"), .init(262, "Caffeine", "mg")
    ]
}

private struct DailyNutrientTarget: Codable {
    let amount: Double
    let isLimit: Bool
    var display: String { isLimit ? "At most" : "At least" }
}

private struct NutrientTargetsEditor: View {
    let nutrients: [DiaryDayDetails.Nutrient]
    let existing: [Int: DailyNutrientTarget]
    let save: ([Int: DailyNutrientTarget]) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 291
    @State private var amount = ""
    @State private var isLimit = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Picker("Nutrient", selection: $selected) {
                    ForEach(nutrients, id: \.id) { nutrient in
                        Text(nutrient.name + (existing[nutrient.id] == nil ? "" : " ✓")).tag(nutrient.id)
                    }
                }
                Picker("Target", selection: $isLimit) {
                    Text("At least").tag(false)
                    Text("At most").tag(true)
                }.pickerStyle(.segmented)
                HStack {
                    Text("Daily amount")
                    TextField("Amount", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    Text(nutrients.first { $0.id == selected }?.unit ?? "")
                }
                if existing[selected] != nil {
                    Button("Remove this target", role: .destructive) { update(nil) }
                }
                if let error { Text(error).foregroundStyle(WarmInk.action) }
            }
            .navigationTitle("Nutrient targets")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .onAppear { load() }
            .onChange(of: selected) { _ in load() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = PortionInput.decimal(amount), value > 0 {
                            update(DailyNutrientTarget(amount: value, isLimit: isLimit))
                        }
                    }.disabled((PortionInput.decimal(amount) ?? 0) <= 0)
                }
            }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }

    private func load() {
        let target = existing[selected]
        amount = target?.amount.formatted(.number.grouping(.never).precision(.fractionLength(0...6))) ?? ""
        isLimit = target?.isLimit ?? false
    }

    private func update(_ target: DailyNutrientTarget?) {
        var result = existing
        result[selected] = target
        do { try save(result); dismiss() } catch { self.error = error.localizedDescription }
    }
}
