import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let dieticMeal = UTType(exportedAs: "co.yotzin.dietic.meal", conformingTo: .data)
}

/// A portable snapshot contains only the selected foods and their portions.
struct SharedMeal: Codable, Identifiable, Transferable {
    let version: Int
    let id: UUID
    let meal: String
    let items: [Item]
    var templateName: String? = nil
    var batchServings: Double? = nil

    struct Item: Codable {
        let food: SavedFood
        let quantity: Double
        let inGrams: Bool

        init(food: SavedFood, quantity: Double, inGrams: Bool) {
            self.food = food
            self.quantity = quantity
            self.inGrams = inGrams
        }

        init(_ sample: HKSampleWithDescription) {
            inGrams = sample.servingSelection == ServingType.gram.description
            quantity = sample.numberOfServings
            // Older gram entries can lack a serving weight. Use one gram as their basis.
            let gramBasis = inGrams && sample.servingWeightGrams <= 0
            let weight = gramBasis ? 1 : sample.servingWeightGrams
            let servings = inGrams ? quantity / weight : quantity
            var nutrients = [Int: Double]()
            for id in sample.attrIDArray {
                if let field = HKSampleWithDescription.nutrientFields[id] {
                    nutrients[id] = sample[keyPath: field] / servings
                }
            }
            food = SavedFood(name: sample.foodName, brand: sample.brandName,
                             servingQuantity: gramBasis ? 1 : sample.servingQuantity,
                             servingUnit: gramBasis ? "g" : sample.servingUnit,
                             servingGrams: weight > 0 ? weight : nil, nutrients: nutrients,
                             householdServing: gramBasis ? nil : sample.householdServing)
        }

        var input: PortionInput {
            PortionInput(portion: food.portion, savedQuantity: quantity, savedAsGrams: inGrams)
        }

        var valid: Bool {
            !food.name.trimmed().isEmpty && food.name.count <= 1024 && (food.brand?.count ?? 0) <= 1024 &&
            food.servingUnit.count <= 256 && (food.householdServing?.count ?? 0) <= 1024 &&
            food.servingQuantity > 0 && food.servingQuantity <= 1_000_000 &&
            (food.servingGrams.map { $0 > 0 && $0 <= 1_000_000 } ?? !inGrams) &&
            quantity > 0 && quantity <= 1_000_000 && !food.nutrients.isEmpty &&
            food.nutrients.allSatisfy { HKSampleWithDescription.nutrientFields[$0.key] != nil && (0...1_000_000_000).contains($0.value) } &&
            canLog(input)
        }

        func canLog(_ input: PortionInput) -> Bool {
            guard let servings = input.servings, let amount = input.savedQuantity,
                  amount <= 1_000_000 && servings <= 1_000_000 else { return false }
            return food.nutrients.values.allSatisfy { $0 * servings <= 1_000_000_000 }
        }
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .dieticMeal) { meal in
            let data = try meal.encoded()
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(meal.id.uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent(meal.filename).appendingPathExtension("dieticmeal")
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }

    private var filename: String {
        guard let templateName else { return meal }
        let words = templateName.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let name = words.joined(separator: " ")
        guard !name.isEmpty else { return meal }
        return String(name.unicodeScalars.prefix(48))
    }

    func encoded() throws -> Data {
        try validate()
        let data = try JSONEncoder().encode(self)
        guard data.count <= Self.maxBytes else { throw ShareError.invalid }
        return data
    }

    private static let maxBytes = 2 * 1024 * 1024

    func validate() throws {
        guard version == 1 else { throw ShareError.version }
        if let name = templateName, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.count > 1024 {
            throw ShareError.invalid
        }
        if let count = batchServings, !count.isFinite || count <= 0 { throw ShareError.invalid }
        guard (EatingTime.allCases.map(\.description) + ["Meal"]).contains(meal),
              (1...200).contains(items.count), items.allSatisfy(\.valid) else { throw ShareError.invalid }
    }

    static func read(_ url: URL) throws -> Self {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        guard let data = try file.read(upToCount: maxBytes + 1), data.count <= maxBytes else { throw ShareError.invalid }
        guard let meal = try? JSONDecoder().decode(Self.self, from: data) else { throw ShareError.invalid }
        try meal.validate()
        return meal
    }

    enum ShareError: LocalizedError {
        case invalid, version, alreadyAdded
        var errorDescription: String? {
            switch self {
            case .invalid: return "This meal file is incomplete or contains an invalid food or portion."
            case .version: return "Update Dietic to open this meal format."
            case .alreadyAdded: return "You already added this shared meal."
            }
        }
    }
}

extension HKSampleWithDescription {
    static let nutrientFields: [Int: WritableKeyPath<Self, Double>] = [
        203: \.protein, 204: \.totalFat, 205: \.totalCarbohydrate, 208: \.calories,
        262: \.caffeine, 269: \.sugars, 291: \.dietaryFiber, 301: \.calcium,
        303: \.iron, 304: \.magnesium, 305: \.phosphorus, 306: \.potassium, 307: \.sodium,
        309: \.zinc, 312: \.copper, 315: \.manganese, 317: \.selenium, 320: \.vitaminA,
        323: \.vitaminE, 328: \.vitaminD, 401: \.vitaminC, 404: \.thiamin, 405: \.riboflavin,
        406: \.niacin, 415: \.vitaminB6, 417: \.folate, 418: \.vitaminB12, 430: \.vitaminK,
        601: \.cholesterol, 606: \.saturatedFat, 645: \.monounsaturatedFat, 646: \.polyunsaturatedFat
    ]
}

struct ShareMealView: View {
    let title: String
    let entries: [HKSampleWithDescription]
    @State private var excluded = Set<String>()
    @State private var shareID = UUID()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let meal = SharedMeal(version: 1, id: shareID, meal: title,
                              items: entries.filter { !excluded.contains($0.id) }.map(SharedMeal.Item.init))
        NavigationStack {
            List {
                Section("Foods to share") {
                    ForEach(entries) { entry in
                        Toggle(isOn: Binding(get: { !excluded.contains(entry.id) }, set: { include in
                            if include { excluded.remove(entry.id) } else { excluded.insert(entry.id) }
                            shareID = UUID()
                        })) {
                            VStack(alignment: .leading) {
                                Text(entry.foodName)
                                Text(entry.portion.description(quantity: entry.numberOfServings, measuredInGrams: entry.servingSelection == ServingType.gram.description))
                                    .font(.caption).foregroundStyle(WarmInk.muted)
                            }
                        }
                    }
                }
                if !meal.items.allSatisfy(\.valid) {
                    Text("Deselect foods with missing nutrition or invalid portions to share this meal.")
                } else if meal.items.count > 200 {
                    Text("Choose up to 200 foods for one meal.")
                }
            }
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                ShareLink(item: meal, preview: SharePreview(title, image: Image(systemName: "fork.knife"))) {
                    Label("Share meal", systemImage: "square.and.arrow.up")
                }.buttonStyle(JournalActionStyle()).disabled((try? meal.validate()) == nil)
                    .padding().background(WarmInk.paper)
            }
            .navigationTitle("Share " + title.lowercased())
            .toolbar { Button("Done") { dismiss() } }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }
}

struct ReceiveMealView: View {
    var onLogged: (() -> Void)?
    let title: String
    let shared: SharedMeal
    @ObservedObject var manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @State private var meal: EatingTime
    @State private var date = Date()
    @State private var inputs: [PortionInput]
    @State private var excluded = Set<Int>()
    @State private var saving = false
    @State private var added: Bool
    @State private var message: String?
    @State private var namingTemplate = false
    @State private var templateName = ""

    init(shared: SharedMeal, manager: FastingManager, title: String = "Shared meal", initialDate: Date = .now, onLogged: (() -> Void)? = nil) {
        self.onLogged = onLogged
        self.title = title
        _date = State(initialValue: initialDate)
        self.shared = shared
        _templateName = State(initialValue: shared.templateName ?? "")
        self.manager = manager
        _inputs = State(initialValue: shared.items.map(\.input))
        _meal = State(initialValue: EatingTime.allCases.first { $0.description == shared.meal } ?? .current)
        _added = State(initialValue: manager.hasImportedMeal(shared.id))
    }

    private var selected: [Int] { shared.items.indices.filter { !excluded.contains($0) } }
    private var ready: Bool { !selected.isEmpty && selected.allSatisfy { shared.items[$0].canLog(inputs[$0]) } }

    var body: some View {
        NavigationStack {
            Form {
                if title == "Shared meal", let name = shared.templateName {
                    Section {
                        Text(name).font(.headline)
                        if let yield = shared.batchServings {
                            LabeledContent("Shared amount", value: yield == 1 ? "1 recipe serving" : "\(yield.formatted()) recipe servings")
                        }
                    }
                }
                if added {
                    Label("Added to your diary", systemImage: "checkmark.circle.fill")
                } else {
                    DatePicker("Diary date", selection: $date, in: ...Date.now, displayedComponents: .date)
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description).tag($0) }
                    }
                    if title == "Shared meal", ready {
                        Button { namingTemplate = true } label: {
                            Label("Save to my meals", systemImage: "bookmark")
                        }
                    }
                }
                if let message { Text(message).foregroundStyle(WarmInk.action) }
                Section(added ? "Logged foods" : "Your portions") {
                    ForEach(added ? selected : Array(shared.items.indices), id: \.self) { index in
                        let item = shared.items[index]
                        VStack(alignment: .leading, spacing: 6) {
                            if added {
                                Text(item.food.name)
                                if let servings = inputs[index].servings {
                                    Text(item.food.portion.description(servings: servings)).font(.caption).foregroundStyle(WarmInk.muted)
                                }
                            }
                            else {
                                Toggle(item.food.name, isOn: Binding(get: { !excluded.contains(index) }, set: { include in
                                    if include { excluded.remove(index) } else { excluded.insert(index) }
                                }))
                                if !excluded.contains(index) {
                                    HStack {
                                        Picker("Measure by", selection: Binding(get: { inputs[index].unit }, set: { inputs[index].select($0) })) {
                                            ForEach(inputs[index].availableUnits, id: \.self) { unit in
                                                Text(inputs[index].label(for: unit)).tag(unit)
                                            }
                                        }.pickerStyle(.menu)
                                        Spacer()
                                        TextField("Quantity", text: $inputs[index].text)
                                            .keyboardType(.numbersAndPunctuation).multilineTextAlignment(.trailing).frame(width: 86)
                                            .accessibilityLabel("Quantity for " + item.food.name)
                                    }
                                    if let count = inputs[index].servings, item.canLog(inputs[index]) {
                                        Text(item.food.portion.description(servings: count))
                                            .font(.caption).foregroundStyle(WarmInk.muted)
                                    }
                                }
                            }
                        }
                    }
                }
                if !added && ready {
                    let calories = selected.reduce(0.0) { total, index in
                        total + (shared.items[index].food.nutrients[208] ?? 0) * (inputs[index].servings ?? 0)
                    }
                    if selected.allSatisfy({ shared.items[$0].food.nutrients[208] != nil }) {
                        LabeledContent("Meal total", value: "\(Int(calories.rounded())) kcal")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                if !added {
                    Button(saving ? "Adding…" : "Add to my diary") { Task { await add() } }
                        .buttonStyle(JournalActionStyle()).disabled(!ready || saving)
                        .padding().background(WarmInk.paper)
                }
            }
            .navigationTitle(title)
            .alert("Save to my meals", isPresented: $namingTemplate) {
                TextField("Meal name", text: $templateName)
                Button("Save") { saveTemplate() }
                    .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button("Cancel", role: .cancel) {}
            }
            .toolbar { Button(added ? "Done" : "Cancel") { dismiss() } }
            .disabled(saving)
        }.interactiveDismissDisabled(saving).tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func saveTemplate() {
        guard ready else { return }
        let foods = selected.compactMap { index -> SharedMeal.Item? in
            let input = inputs[index]
            guard let quantity = input.savedQuantity else { return nil }
            return SharedMeal.Item(food: shared.items[index].food, quantity: quantity, inGrams: input.savedUnit == .gram)
        }
        do {
            try MealTemplateLibrary.shared.save(name: templateName, meal: meal.description,
                                                foods: foods, batchServings: shared.batchServings)
            message = "Saved to your meals."
        } catch { message = error.localizedDescription }
    }

    @MainActor private func add() async {
        guard ready, !saving, !added else { return }
        saving = true
        defer { saving = false }
        let samples = selected.compactMap { index -> HKSampleWithDescription? in
            let input = inputs[index]
            guard let multiplier = input.servings, let quantity = input.savedQuantity else { return nil }
            return shared.items[index].food.sample(multiplier: multiplier, quantity: quantity, unit: input.savedUnit, meal: meal, date: date)
        }
        do {
            try await manager.importMeal(samples, id: shared.id)
            manager.selectDay(date)
            added = true
            onLogged?()
        } catch SharedMeal.ShareError.alreadyAdded {
            added = manager.hasImportedMeal(shared.id)
            if added { onLogged?() }
        }
        catch { message = error.localizedDescription }
    }
}
