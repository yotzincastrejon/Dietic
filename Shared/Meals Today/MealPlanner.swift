import SwiftUI

private struct PlannedMeal: Codable, Identifiable {
    var name: String
    var day: DateComponents
    let meal: SharedMeal
    var id: UUID { meal.id }

    var date: Date {
        Calendar(identifier: .gregorian).date(from: day) ?? .distantPast
    }
}

private enum PlannedMealSheet: Identifiable {
    case create, shopping, review(PlannedMeal), reschedule(PlannedMeal)
    var id: String {
        switch self {
        case .create: return "create"
        case .shopping: return "shopping"
        case .review(let item): return "review-" + item.id.uuidString
        case .reschedule(let item): return "schedule-" + item.id.uuidString
        }
    }
}

struct MealPlannerView: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("plannedMeals.v1") private var stored = Data()
    @State private var sheet: PlannedMealSheet?
    @State private var removing: PlannedMeal?
    @State private var error: String?
    @State private var revision = 0

    private func read() throws -> [PlannedMeal] {
        guard !stored.isEmpty else { return [] }
        return try JSONDecoder().decode([PlannedMeal].self, from: stored)
    }

    private func write(_ changes: (inout [PlannedMeal]) -> Void) throws {
        var all = try read()
        changes(&all)
        stored = try JSONEncoder().encode(all)
    }

    var body: some View {
        NavigationStack {
            let all = try? read()
            let pending = (all ?? []).filter { !manager.hasImportedMeal($0.id) }.sorted { $0.date < $1.date }
            List {
                if all == nil { Text("This meal plan could not be read.") }
                else if pending.isEmpty {
                    Text("Choose a saved meal or recipe and schedule it. When you eat it, review your portions and log it.")
                        .foregroundStyle(WarmInk.muted)
                }
                ForEach(pending) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.date.formatted(date: .abbreviated, time: .omitted) + " · " + item.meal.meal)
                            .font(.caption.weight(.medium)).foregroundStyle(WarmInk.muted)
                        Text(item.name).font(.headline)
                        Text(item.meal.items.map(\.food.name).joined(separator: ", ")).font(.subheadline).lineLimit(2)
                        HStack {
                            if item.date <= .now {
                                Button("Review & log") { sheet = .review(item) }
                            }
                            Button("Reschedule") { sheet = .reschedule(item) }
                            Spacer()
                            Button(role: .destructive) { removing = item } label: { Image(systemName: "trash") }
                                .accessibilityLabel("Remove " + item.name)
                        }.buttonStyle(.borderless).font(.subheadline)
                    }.padding(.vertical, 4)
                }
            }.id(revision)
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Meal planner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { sheet = .shopping } label: { Image(systemName: "basket") }
                        .accessibilityLabel("Shopping list")
                    Button { sheet = .create } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Plan a meal").disabled(all == nil)
                }
            }
            .sheet(item: $sheet, onDismiss: { revision += 1 }) { route in
                switch route {
                case .shopping:
                    PlannedShoppingList(meals: pending)
                case .create:
                    ScheduleMealView(manager: manager) { item in
                        try write { $0.append(item) }
                    }
                case .reschedule(let item):
                    RescheduleMealView(item: item) { date in
                        try write { items in
                            if let index = items.firstIndex(where: { $0.id == item.id }) {
                                items[index].day = date
                            }
                        }
                    }
                case .review(let item):
                    ReceiveMealView(shared: item.meal, manager: manager,
                                    title: item.name, initialDate: item.date) {
                        do { try write { $0.removeAll { $0.id == item.id } } }
                        catch { self.error = error.localizedDescription }
                    }
                }
            }
            .alert("Remove planned meal?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
                   presenting: removing) { item in
                Button("Remove", role: .destructive) {
                    do { try write { $0.removeAll { $0.id == item.id } } } catch { self.error = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            } message: { item in Text(item.name) }
            .alert("Meal planner", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") {}
            } message: { Text(error ?? "") }
            .onAppear { pruneLogged() }
            .onChange(of: revision) { _ in pruneLogged() }
        }.preferredColorScheme(.light).tint(WarmInk.action)
    }

    private func pruneLogged() {
        do {
            if try read().contains(where: { manager.hasImportedMeal($0.id) }) {
                try write { $0.removeAll { manager.hasImportedMeal($0.id) } }
            }
        } catch { self.error = error.localizedDescription }
    }
}

private struct RescheduleMealView: View {
    let item: PlannedMeal
    let save: (DateComponents) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var error: String?

    init(item: PlannedMeal, save: @escaping (DateComponents) throws -> Void) {
        self.item = item
        self.save = save
        _date = State(initialValue: max(item.date, Calendar.current.startOfDay(for: .now)))
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, in: Calendar.current.startOfDay(for: .now)...,
                           displayedComponents: .date).datePickerStyle(.graphical)
                if let error { Text(error) }
            }
            .navigationTitle("Reschedule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try save(Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date))
                            dismiss()
                        } catch { self.error = error.localizedDescription }
                    }
                }
            }
        }
    }
}

private struct ScheduleMealView: View {
    let manager: FastingManager
    let save: (PlannedMeal) throws -> Void
    @ObservedObject private var library = MealTemplateLibrary.shared
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var meal = EatingTime.current
    @State private var selected: UUID?
    @State private var portions = "1"
    @State private var error: String?
    private var template: MealTemplate? { library.templates.first { $0.id == selected } }

    private var planned: PlannedMeal? {
        guard let template else { return nil }
        let items: [SharedMeal.Item]
        if template.batchServings != nil {
            guard let servings = PortionInput.parseAmount(portions),
                  let inputs = template.scaledInputs(for: servings) else { return nil }
            items = zip(template.foods, inputs).compactMap { item, input in
                guard let quantity = input.savedQuantity else { return nil }
                return SharedMeal.Item(food: item.food, quantity: quantity, inGrams: input.unit == .grams)
            }
            guard items.count == template.foods.count else { return nil }
        } else { items = template.foods }
        return PlannedMeal(name: template.name, day: Calendar(identifier: .gregorian).dateComponents([.year,.month,.day], from: date),
                           meal: SharedMeal(version: 1, id: UUID(), meal: meal.description, items: items))
    }

    var body: some View {
        NavigationStack {
            Form {
                if library.templates.isEmpty {
                    Text("Create a recipe in Saved meals or expand a logged meal and tap Save meal first.")
                } else {
                    Picker("Saved meal", selection: $selected) {
                        ForEach(library.templates) { Text($0.name).tag(Optional($0.id)) }
                    }
                    if template?.batchServings != nil {
                        HStack {
                            Text("Recipe servings")
                            TextField("Servings", text: $portions).multilineTextAlignment(.trailing).keyboardType(.numbersAndPunctuation)
                        }
                    }
                    DatePicker("Planned date", selection: $date, in: Calendar.current.startOfDay(for: .now)..., displayedComponents: .date)
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description) }
                    }
                }
                if let error { Text(error).foregroundStyle(WarmInk.action) }
            }
            .navigationTitle("Plan a meal")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        guard let planned else { return }
                        do { try save(planned); dismiss() } catch { self.error = error.localizedDescription }
                    }.disabled(planned == nil)
                }
            }
            .task {
                do { try library.reload(); selected = library.templates.first?.id }
                catch { self.error = error.localizedDescription }
            }
            .onChange(of: selected) { _ in
                if let period = EatingTime.allCases.first(where: { $0.description == template?.meal }) { meal = period }
                portions = "1"
            }
        }
    }
}

private struct ShoppingIngredient: Identifiable {
    let food: SavedFood
    let id: String
    var amount: Double
    let inGrams: Bool
    var portion: String { food.portion.description(quantity: amount, measuredInGrams: inGrams) }
    var checkKey: String { id + "|" + String(amount) }

    static func ingredients(for meals: [PlannedMeal]) -> [Self] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return [] }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        var result: [String: Self] = [:]
        for meal in meals where (start..<end).contains(meal.date) {
            for item in meal.meal.items {
                // Combine servings and gram entries only when their actual serving mass is known.
                let grams = item.food.portion.grams
                let rawGrams = item.inGrams && (grams ?? 0) <= 0
                let amount = item.inGrams && !rawGrams ? item.quantity / (grams ?? 1) : item.quantity
                guard amount.isFinite, amount > 0, let encoded = try? encoder.encode(item.food) else { continue }
                let id = encoded.base64EncodedString() + (rawGrams ? "-g" : "-servings")
                if result[id] == nil { result[id] = Self(food: item.food, id: id, amount: 0, inGrams: rawGrams) }
                result[id]?.amount += amount
            }
        }
        return result.values.sorted {
            if $0.food.name == $1.food.name { return $0.id < $1.id }
            return $0.food.name.localizedStandardCompare($1.food.name) == .orderedAscending
        }
    }
}

private struct PlannedShoppingList: View {
    let meals: [PlannedMeal]
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shoppingChecks.v1") private var stored = Data()
    private var checked: Set<String> { (try? JSONDecoder().decode(Set<String>.self, from: stored)) ?? [] }

    var body: some View {
        let items = ShoppingIngredient.ingredients(for: meals)
        let keys = Set(items.map(\.checkKey))
        NavigationStack {
            List {
                Section("Next 7 days") {
                    if items.isEmpty { Text("Schedule a meal this week to see its ingredients here.").foregroundStyle(WarmInk.muted) }
                    ForEach(items) { item in
                        Button {
                            var updated = checked.intersection(keys)
                            if !updated.insert(item.checkKey).inserted { updated.remove(item.checkKey) }
                            if let data = try? JSONEncoder().encode(updated) { stored = data }
                        } label: {
                            HStack {
                                Image(systemName: checked.contains(item.checkKey) ? "checkmark.circle.fill" : "circle")
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.food.name).strikethrough(checked.contains(item.checkKey)).foregroundStyle(WarmInk.text)
                                    Text([item.food.brand, item.portion].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(WarmInk.muted)
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(item.food.name)
                        .accessibilityValue((checked.contains(item.checkKey) ? "Checked, " : "Unchecked, ") + item.portion)
                        .accessibilityAddTraits(checked.contains(item.checkKey) ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("Shopping list")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                if !items.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: items.map { "• " + $0.food.name + " — " + $0.portion }.joined(separator: "\n"))
                    }
                }
            }
        }
    }
}
