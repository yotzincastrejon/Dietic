import SwiftUI

struct MealTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let meal: String
    let foods: [SharedMeal.Item]
    let batchServings: Double?

    func scaledInputs(for servingsEaten: Double) -> [PortionInput]? {
        guard let batchServings else { return nil }
        return Self.scaledInputs(foods, yield: batchServings, servingsEaten: servingsEaten)
    }

    static func scaledInputs(_ foods: [SharedMeal.Item], yield: Double, servingsEaten: Double) -> [PortionInput]? {
        guard yield.isFinite, yield > 0, servingsEaten.isFinite, servingsEaten > 0 else { return nil }
        let fraction = servingsEaten / yield
        let portions = foods.map { item in
            PortionInput(portion: item.food.portion, savedQuantity: item.quantity * fraction, savedAsGrams: item.inGrams)
        }
        return zip(foods, portions).allSatisfy { $0.canLog($1) } ? portions : nil
    }
}

/// Reload before each mutation so a stale view cannot overwrite a newer library.
@MainActor
final class MealTemplateLibrary: ObservableObject {
    static let shared = MealTemplateLibrary()
    @Published private(set) var templates: [MealTemplate] = []
    private let url: URL

    init(directory: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]) {
        url = directory.appendingPathComponent("MealTemplates.json")
    }

    func reload() throws {
        do {
            templates = try JSONDecoder().decode([MealTemplate].self, from: Data(contentsOf: url))
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            templates = []
        }
    }

    @discardableResult
    func save(id: UUID? = nil, name: String, meal: String, foods: [SharedMeal.Item], batchServings: Double? = nil) throws -> MealTemplate {
        try reload()
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw LibraryError.missingName }
        guard !foods.isEmpty, foods.allSatisfy(\.valid) else { throw LibraryError.invalidFoods }
        guard !templates.contains(where: { $0.id != id && $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) else {
            throw LibraryError.duplicateName
        }
        if let batchServings, !batchServings.isFinite || batchServings <= 0 { throw LibraryError.invalidYield }
        let result = MealTemplate(id: id ?? UUID(), name: name, meal: meal, foods: foods, batchServings: batchServings)
        var updated = templates
        if let id {
            guard let index = updated.firstIndex(where: { $0.id == id }) else { throw LibraryError.missingMeal }
            updated[index] = result
        } else {
            updated.insert(result, at: 0)
        }
        try write(updated)
        return result
    }

    func delete(id: UUID) throws {
        try reload()
        try write(templates.filter { $0.id != id })
    }

    private func write(_ updated: [MealTemplate]) throws {
        let data = try JSONEncoder().encode(updated)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        templates = updated
    }

    enum LibraryError: LocalizedError {
        case missingName, invalidFoods, duplicateName, invalidYield, missingMeal
        var errorDescription: String? {
            switch self {
            case .missingName: return "Enter a name for this meal."
            case .invalidFoods: return "Choose at least one food with a valid portion and nutrition."
            case .duplicateName: return "You already have a saved meal with that name."
            case .invalidYield: return "Enter how many servings the full recipe makes."
            case .missingMeal: return "This meal is no longer in your saved meals."
            }
        }
    }
}

struct SaveMealTemplateView: View {
    let mealName: String
    let entries: [HKSampleWithDescription]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isRecipe = false
    @State private var batch = ""
    @State private var excluded = Set<String>()
    @State private var error: String?

    var body: some View {
        let selected = entries.filter { !excluded.contains($0.id) }
        NavigationStack {
            Form {
                Section("Meal name") {
                    TextField("e.g. Weekday breakfast", text: $name).submitLabel(.done)
                        .accessibilityLabel("Meal name")
                }
                Section {
                    Toggle("Save as a recipe", isOn: $isRecipe)
                    if isRecipe {
                        LabeledContent("Servings in full recipe") {
                            TextField("e.g. 4", text: $batch).keyboardType(.numbersAndPunctuation)
                                .multilineTextAlignment(.trailing).accessibilityIdentifier("recipe-batch-servings")
                        }
                    }
                }
                Section(isRecipe ? "Ingredients in full recipe" : "Foods to save") {
                    ForEach(entries) { entry in
                        Toggle(isOn: Binding(get: { !excluded.contains(entry.id) }, set: { include in
                            if include { excluded.remove(entry.id) } else { excluded.insert(entry.id) }
                        })) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(entry.foodName)
                                Text(entry.portion.description(quantity: entry.numberOfServings,
                                                               measuredInGrams: entry.servingSelection == ServingType.gram.description))
                                    .font(.caption).foregroundStyle(WarmInk.muted)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                Button("Save meal") {
                    do {
                        try MealTemplateLibrary.shared.save(name: name, meal: mealName, foods: selected.map(SharedMeal.Item.init),
                                                           batchServings: isRecipe ? PortionInput.parseAmount(batch) : nil)
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }.buttonStyle(JournalActionStyle())
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selected.isEmpty || (isRecipe && PortionInput.parseAmount(batch) == nil))
                    .padding().background(WarmInk.paper)
            }
            .navigationTitle("Save meal")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .alert("Couldn’t save meal", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") {}
            } message: { Text(error ?? "") }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }
}

struct SavedMealsView: View {
    let manager: FastingManager
    @ObservedObject private var library = MealTemplateLibrary.shared
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var error: String?
    @State private var pendingDelete: MealTemplate?
    @State private var creatingRecipe = false

    private var matches: [MealTemplate] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return library.templates.filter { template in
            term.isEmpty || template.name.localizedCaseInsensitiveContains(term) ||
            template.foods.contains { $0.food.name.localizedCaseInsensitiveContains(term) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    Text(error)
                    Button("Try again") { load() }
                } else if library.templates.isEmpty {
                    Text("Tap + to build a recipe, or expand a meal in your diary and choose Save meal to keep its foods and portions.")
                        .foregroundStyle(WarmInk.muted)
                } else if matches.isEmpty {
                    Text("No matching saved meals.").foregroundStyle(WarmInk.muted)
                }
                ForEach(matches) { template in
                    NavigationLink {
                        LogMealTemplateView(template: template, manager: manager, onLogged: { dismiss() })
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.headline)
                            if let yield = template.batchServings {
                                Text("Recipe · Makes \(yield.formatted()) servings").font(.caption).foregroundStyle(WarmInk.muted)
                            }
                            Text(template.foods.map(\.food.name).joined(separator: ", "))
                                .font(.caption).foregroundStyle(WarmInk.muted).lineLimit(2)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { pendingDelete = template }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Saved meals")
            .searchable(text: $query, prompt: "Search meals or foods")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { creatingRecipe = true } label: { Label("New recipe", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $creatingRecipe) {
                RecipeEditor(template: nil) { _ in query = ""; error = nil }
            }
            .task { load() }
            .alert("Delete this saved meal?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
                   presenting: pendingDelete) { template in
                Button("Delete", role: .destructive) {
                    do { try library.delete(id: template.id) } catch { self.error = error.localizedDescription }
                }
                Button("Cancel", role: .cancel) {}
            } message: { template in Text(template.name) }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func load() {
        do { try library.reload(); error = nil } catch { self.error = error.localizedDescription }
    }
}

private struct LogMealTemplateView: View {
    @State private var template: MealTemplate
    let manager: FastingManager
    let onLogged: () -> Void
    @State private var meal: EatingTime
    @State private var inputs: [PortionInput]
    @State private var servingsEaten = "1"
    @State private var editingRecipe = false
    @State private var sharing = false
    @State private var excluded = Set<Int>()
    @State private var saving = false
    @State private var error: String?

    init(template: MealTemplate, manager: FastingManager, onLogged: @escaping () -> Void) {
        _template = State(initialValue: template)
        self.manager = manager
        self.onLogged = onLogged
        _meal = State(initialValue: EatingTime.allCases.first { $0.description == template.meal } ?? .current)
        _inputs = State(initialValue: template.foods.map(\.input))
    }

    private var included: [Int] {
        template.foods.indices.filter { template.batchServings != nil || !excluded.contains($0) }
    }

    private var activeInputs: [PortionInput]? {
        guard template.batchServings != nil else { return inputs }
        return PortionInput.parseAmount(servingsEaten).flatMap { template.scaledInputs(for: $0) }
    }

    private func ready(_ amounts: [PortionInput]?) -> Bool {
        guard let amounts else { return false }
        return !included.isEmpty && included.allSatisfy { template.foods[$0].canLog(amounts[$0]) }
    }

    var body: some View {
        let amounts = activeInputs
        Form {
            Section(manager.mealTimestamp.formatted(date: .complete, time: .omitted)) {
                Picker("Meal", selection: $meal) {
                    ForEach(EatingTime.allCases, id: \.self) { Text($0.description).tag($0) }
                }
            }
            if let yield = template.batchServings {
                Section("Your portion") {
                    LabeledContent("Full recipe makes", value: "\(yield.formatted()) servings")
                    LabeledContent("Servings eaten") {
                        TextField("Amount", text: $servingsEaten).keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing).accessibilityIdentifier("recipe-servings-eaten")
                    }
                }
            }
            Section(template.batchServings == nil ? "Foods and portions" : "Ingredients in your portion") {
                ForEach(template.foods.indices, id: \.self) { index in
                    let item = template.foods[index]
                    if template.batchServings != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.food.name)
                            if let servings = amounts?[index].servings {
                                Text(item.food.portion.description(servings: servings)).font(.caption).foregroundStyle(WarmInk.muted)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(item.food.name, isOn: Binding(get: { !excluded.contains(index) }, set: { include in
                                if include { excluded.remove(index) } else { excluded.insert(index) }
                            }))
                            if !excluded.contains(index) {
                                IngredientAmountView(food: item.food, input: $inputs[index])
                                if let servings = inputs[index].servings, item.canLog(inputs[index]) {
                                    Text(item.food.portion.description(servings: servings)).font(.caption).foregroundStyle(WarmInk.muted)
                                }
                            }
                        }
                    }
                }
            }
            if let amounts, ready(amounts) {
                MealNutritionSummary(title: "Meal total", items: included.map { template.foods[$0] },
                                     amounts: included.map { amounts[$0] })
            }
        }.scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden).background(WarmInk.paper)
        .safeAreaInset(edge: .bottom) {
            Button(saving ? "Logging…" : "Log to " + meal.description.lowercased()) {
                Task { await log() }
            }.buttonStyle(JournalActionStyle()).disabled(!ready(amounts) || saving)
                .padding().background(WarmInk.paper)
        }
        .navigationTitle(template.name).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { sharing = true } label: { Label("Share saved meal", systemImage: "square.and.arrow.up") }.disabled(saving)
            Button(template.batchServings == nil ? "Make recipe" : "Edit recipe") { editingRecipe = true }.disabled(saving)
        }
        .sheet(isPresented: $sharing) { ShareTemplateView(template: template) }
        .sheet(isPresented: $editingRecipe) {
            RecipeEditor(template: template) { updated in
                template = updated
                inputs = updated.foods.map(\.input)
                excluded = []
                servingsEaten = "1"
                meal = EatingTime.allCases.first { $0.description == updated.meal } ?? meal
            }
        }
        .disabled(saving).navigationBarBackButtonHidden(saving).interactiveDismissDisabled(saving)
        .alert("Couldn’t log meal", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK") {}
        } message: { Text(error ?? "") }
    }

    @MainActor private func log() async {
        guard !saving, let amounts = activeInputs, ready(amounts) else { return }
        saving = true
        let date = manager.mealTimestamp
        let samples = included.compactMap { index -> HKSampleWithDescription? in
            let input = amounts[index]
            guard let multiplier = input.servings, let quantity = input.savedQuantity else { return nil }
            return template.foods[index].food.sample(multiplier: multiplier, quantity: quantity, unit: input.savedUnit, meal: meal, date: date)
        }
        do {
            try await manager.saveMeals(samples)
            onLogged()
        } catch {
            self.error = error.localizedDescription
            saving = false
        }
    }
}

private struct MealNutritionSummary: View {
    let title: String
    let items: [SharedMeal.Item]
    let amounts: [PortionInput]
    @Environment(\.dynamicTypeSize) private var typeSize

    private func total(_ nutrient: Int) -> Double? {
        var result = 0.0
        for (item, amount) in zip(items, amounts) {
            guard let value = item.food.nutrients[nutrient], let servings = amount.servings else { return nil }
            result += value * servings
        }
        return result
    }

    var body: some View {
        Section {
            if let calories = total(208) {
                LabeledContent(title, value: "\(calories.formatted(.number.precision(.fractionLength(0)))) kcal")
            }
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 8))
            layout {
                macro("Protein", id: 203)
                macro("Carbs", id: 205)
                macro("Fat", id: 204)
            }
        }
    }

    private func macro(_ name: String, id: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(.caption).foregroundStyle(WarmInk.muted)
            Text(total(id).map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) g" } ?? "—")
                .font(.subheadline.weight(.medium))
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }
}

private struct IngredientAmountView: View {
    let food: SavedFood
    @Binding var input: PortionInput

    var body: some View {
        HStack {
            TextField("Amount", text: $input.text)
                .keyboardType(.numbersAndPunctuation).textFieldStyle(.roundedBorder)
                .accessibilityLabel("Quantity for " + food.name)
            Picker("Unit for " + food.name, selection: Binding(get: { input.unit }, set: { input.select($0) })) {
                ForEach(input.availableUnits, id: \.self) { Text(input.label(for: $0)).tag($0) }
            }.labelsHidden().pickerStyle(.menu)
        }
    }
}

private struct RecipeIngredient: Identifiable {
    let id = UUID()
    let food: SavedFood
    var input: PortionInput

    var item: SharedMeal.Item? {
        guard let amount = input.savedQuantity else { return nil }
        let item = SharedMeal.Item(food: food, quantity: amount, inGrams: input.savedUnit == .gram)
        return item.valid ? item : nil
    }
}

private struct RecipeEditor: View {
    let template: MealTemplate?
    let update: (MealTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var batch: String
    @State private var meal: EatingTime
    @State private var ingredients: [RecipeIngredient]
    @State private var searching = false
    @State private var error: String?

    init(template: MealTemplate?, update: @escaping (MealTemplate) -> Void) {
        self.template = template
        self.update = update
        _name = State(initialValue: template?.name ?? "")
        _batch = State(initialValue: template?.batchServings.map { $0.formatted(.number.grouping(.never)) } ?? "")
        _meal = State(initialValue: EatingTime.allCases.first { $0.description == template?.meal } ?? .current)
        _ingredients = State(initialValue: template?.foods.map { RecipeIngredient(food: $0.food, input: $0.input) } ?? [])
    }

    private var ready: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !ingredients.isEmpty &&
        ingredients.allSatisfy { $0.item != nil }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe name", text: $name)
                    LabeledContent("Servings in full recipe") {
                        TextField("e.g. 4", text: $batch).keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing).accessibilityIdentifier("recipe-batch-servings")
                    }
                    Picker("Usual meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description).tag($0) }
                    }
                }
                Section("Ingredients in full recipe") {
                    ForEach($ingredients) { $ingredient in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(ingredient.food.name)
                            if let brand = ingredient.food.brand, !brand.isEmpty {
                                Text(brand).font(.caption).foregroundStyle(WarmInk.muted)
                            }
                            IngredientAmountView(food: ingredient.food, input: $ingredient.input)
                            if let servings = ingredient.input.servings {
                                Text(ingredient.food.portion.description(servings: servings))
                                    .font(.caption).foregroundStyle(WarmInk.muted)
                            }
                        }
                    }.onDelete { ingredients.remove(atOffsets: $0) }
                    Button { searching = true } label: { Label("Add ingredient", systemImage: "plus.circle") }
                }
                if ready, let yield = PortionInput.parseAmount(batch) {
                    let items = ingredients.compactMap(\.item)
                    if let amounts = MealTemplate.scaledInputs(items, yield: yield, servingsEaten: 1) {
                        MealNutritionSummary(title: "Per serving", items: items, amounts: amounts)
                    }
                }
                if template?.batchServings != nil {
                    Button("Save as regular meal") { save(yield: nil) }.disabled(!ready)
                }
            }.scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle(template == nil ? "New recipe" : "Edit recipe").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { if let count = PortionInput.parseAmount(batch) { save(yield: count) } }
                        .disabled(!ready || PortionInput.parseAmount(batch) == nil)
                }
            }
            .sheet(isPresented: $searching) {
                FoodSelectionView(query: "") { food in
                    ingredients.append(RecipeIngredient(food: food, input: PortionInput(portion: food.portion)))
                    searching = false
                }
            }
            .alert("Couldn’t save recipe", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") {}
            } message: { Text(error ?? "") }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func save(yield: Double?) {
        guard ready else { return }
        do {
            let saved = try MealTemplateLibrary.shared.save(id: template?.id, name: name, meal: meal.description,
                                                           foods: ingredients.compactMap(\.item), batchServings: yield)
            update(saved)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}

private struct ShareTemplateView: View {
    let template: MealTemplate
    @Environment(\.dismiss) private var dismiss
    @State private var oneServing = true
    @State private var singleID = UUID()
    @State private var batchID = UUID()

    private var attachment: SharedMeal? {
        var foods = template.foods
        var yield = template.batchServings
        let single = oneServing && yield != nil
        if single {
            guard let inputs = template.scaledInputs(for: 1) else { return nil }
            foods = zip(foods, inputs).compactMap { original, input in
                guard let amount = input.savedQuantity else { return nil }
                return SharedMeal.Item(food: original.food, quantity: amount, inGrams: input.savedUnit == .gram)
            }
            yield = 1
        }
        let period = EatingTime.allCases.first { $0.description == template.meal }?.description ?? "Meal"
        let shared = SharedMeal(version: 1, id: single ? singleID : batchID, meal: period, items: foods,
                                templateName: template.name, batchServings: yield)
        return (try? shared.validate()) != nil ? shared : nil
    }

    var body: some View {
        NavigationStack {
            List {
                if template.batchServings != nil {
                    Picker("Amount to share", selection: $oneServing) {
                        Text("One serving").tag(true)
                        Text("Full recipe").tag(false)
                    }.pickerStyle(.segmented)
                }
                if let attachment {
                    Section("Foods to share") {
                        ForEach(attachment.items.indices, id: \.self) { index in
                            let item = attachment.items[index]
                            LabeledContent(item.food.name, value: item.food.portion.description(quantity: item.quantity,
                                                                                                 measuredInGrams: item.inGrams))
                        }
                    }
                    MealNutritionSummary(title: "Total", items: attachment.items, amounts: attachment.items.map(\.input))
                } else {
                    Text("These portions exceed the meal file’s limits. Adjust the recipe before sharing.")
                }
            }.scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Share " + template.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .safeAreaInset(edge: .bottom) {
                if let attachment {
                    ShareLink(item: attachment, preview: SharePreview(template.name, image: Image(systemName: "fork.knife"))) {
                        Label("Share meal file", systemImage: "square.and.arrow.up")
                    }.buttonStyle(JournalActionStyle()).padding().background(WarmInk.paper)
                }
            }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }
}
