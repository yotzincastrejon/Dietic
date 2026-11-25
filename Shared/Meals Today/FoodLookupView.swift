//
//  FoodLookupView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/9/22.
//

import SwiftUI
import CoreData

struct FoodLookupView: View {
    @Binding var isShowing: Bool
    @Binding var rootIsActive: Bool
    @ObservedObject var fastingManager: FastingManager
    let lookup: FoodLookup
    let mealPeriod: EatingTime
    @State private var food: SavedFood?
    @State private var errorMessage: String?

    @State private var libraryError: String?
    @State private var editor: BarcodeEditor?
    @State private var attempt = 0

    var body: some View {
        Group {
            if let food {
                FoodServingView(fastingManager: fastingManager, isShowing: $isShowing,
                                rootIsActive: $rootIsActive, selection: mealPeriod, food: food,
                                barcodeKey: lookup.barcodeKey)
                    .id(attempt)
            } else if let errorMessage {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        JournalHeading(title: "Food lookup", subtitle: lookup.digits)
                        VStack(alignment: .leading, spacing: 14) {
                            Text(errorMessage)
                            if lookup.barcodeKey != nil {
                                Text("Choose a matching food or enter the label. Dietic will remember this barcode on this device.")
                                    .font(.subheadline).foregroundStyle(WarmInk.muted)
                                Button("Find food by name") { editor = .search }.buttonStyle(JournalActionStyle())
                                Button("Enter package label") { editor = .label }.frame(minHeight: 44)
                            }
                            Button("Try lookup again") { attempt += 1 }
                            Button("Back") { isShowing = false }
                        }.padding(.horizontal, 22)
                    }
                }.journalPage()
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    JournalHeading(title: "Food lookup")
                    ProgressView("Looking up food…").padding(.horizontal, 22)
                }.journalPage()
            }
        }
        .toolbar {
            if let key = lookup.barcodeKey, food != nil {
                Menu {
                    Button("Change matching food") { editor = .search }
                    Button("Edit package label") { editor = .label }
                    if BarcodeFoods.shared.food(for: key) != nil {
                        Button("Forget saved match") {
                            do {
                                try BarcodeFoods.shared.forget(key)
                                isShowing = false
                            } catch {
                                libraryError = error.localizedDescription
                            }
                        }
                    }
                } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("Barcode options")
            }
        }
        .alert("Saved groceries", isPresented: Binding(get: { libraryError != nil }, set: { if !$0 { libraryError = nil } })) {
            Button("OK") { libraryError = nil }
        } message: { Text(libraryError ?? "") }
        .sheet(item: $editor) { mode in
            if let key = lookup.barcodeKey {
                BarcodeEditorView(mode: mode, digits: lookup.digits ?? key, initial: food) { chosen in
                    try BarcodeFoods.shared.save(chosen, for: key)
                    attempt += 1
                    editor = nil
                }
            }
        }
        .task(id: LookupAttempt(lookup: lookup, attempt: attempt)) {
            food = nil
            errorMessage = nil
            do {
                let result: SavedFood
                if attempt > 0, let key = lookup.barcodeKey, let saved = BarcodeFoods.shared.food(for: key) {
                    result = saved
                } else {
                    result = try await FoodDataCentral().product(for: lookup)
                }
                try Task.checkCancellation()
                food = result
            } catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription }
            }
        }
    }

    private struct LookupAttempt: Equatable {
        let lookup: FoodLookup
        let attempt: Int
    }
}

struct FoodServingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var fastingManager: FastingManager
    @Binding var isShowing: Bool
    @Binding var rootIsActive: Bool
    @State var selection: EatingTime
    let food: SavedFood
    var historyItem: SearchedFoods?
    let barcodeKey: String?
    let onEntryLogged: ((HKSampleWithDescription) -> Void)?
    let onLogged: ((EatingTime) -> Void)?
    @State private var input: PortionInput
    @ObservedObject private var favorites = FavoriteFoods.shared
    @State private var saving = false
    @State private var logged = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(fastingManager: FastingManager, isShowing: Binding<Bool>, rootIsActive: Binding<Bool>,
         selection: EatingTime, food: SavedFood, historyItem: SearchedFoods? = nil,
         barcodeKey: String? = nil, initialInput: PortionInput? = nil, onEntryLogged: ((HKSampleWithDescription) -> Void)? = nil, onLogged: ((EatingTime) -> Void)? = nil) {
        self.fastingManager = fastingManager
        _isShowing = isShowing
        _rootIsActive = rootIsActive
        _selection = State(initialValue: selection)
        self.food = food
        self.barcodeKey = barcodeKey
        self.onEntryLogged = onEntryLogged
        self.onLogged = onLogged
        self.historyItem = historyItem
        _input = State(initialValue: initialInput ?? PortionInput(portion: food.portion))
    }

    var body: some View {
        ServingPage(name: food.name, meal: $selection, input: $input,
                    calories: displayNutrient(208), carbs: displayNutrient(205), protein: displayNutrient(203),
                    fat: displayNutrient(204), actionTitle: saving ? "Saving…" : "Add to \(selection.description.lowercased())",
                    canSave: input.servings != nil && !saving && !logged, save: {
            guard !saving, !logged, input.servings != nil else { return }
            saving = true
            Task { await logMeal() }
        }, sourceName: food.sourceName, sourceURL: food.sourceURL)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let entry = favorites.entries.first(where: { $0.matches(food) }) {
                    Menu {
                        Button("Update favorite portion") { saveFavorite() }
                            .disabled(input.servings == nil)
                        Button("Remove from favorites", role: .destructive) {
                            do { try favorites.remove(entry.id) }
                            catch { errorMessage = error.localizedDescription; showError = true }
                        }
                    } label: { Image(systemName: "star.fill") }
                    .accessibilityLabel("Favorite options")
                } else {
                    Button { saveFavorite() } label: { Image(systemName: "star") }
                        .accessibilityLabel("Save favorite portion")
                        .disabled(input.servings == nil)
                }
            }
        }
        .disabled(saving)
        .alert("Meal log", isPresented: $showError) {
            Button("OK") { if logged { finish() } }
        } message: { Text(errorMessage) }
    }

    private func saveFavorite() {
        do { try favorites.save(food, input: input) }
        catch { errorMessage = error.localizedDescription; showError = true }
    }

    private func displayNutrient(_ id: Int) -> String {
        guard let value = food.nutrients[id] else { return "—" }
        let total = value * (input.servings ?? 0) * (input.portion.scale(relativeTo: food.portion) ?? 1)
        return total.formatted(.number.precision(.fractionLength(0...1)))
    }

    @MainActor private func logMeal() async {
        defer { saving = false }
        guard let quantity = input.savedQuantity, let multiplier = input.servings else { return }
        do {
            let loggedFood = food.using(input.portion)
            let sample = loggedFood.sample(multiplier: multiplier, quantity: quantity, unit: input.savedUnit,
                                     meal: selection, date: fastingManager.mealTimestamp)
            try await fastingManager.saveMeal(sample)
            onEntryLogged?(sample)
            logged = true
            if let id = food.fdcID, food.portion != input.portion, let data = try? JSONEncoder().encode(input.portion) {
                UserDefaults.standard.set(data, forKey: "packagePortion.\(id)")
            }
            if let barcodeKey, input.portion != food.portion {
                try BarcodeFoods.shared.save(loggedFood, for: barcodeKey)
            }
            try loggedFood.recordHistory(in: viewContext, updating: historyItem)
            finish()
        } catch {
            errorMessage = logged ? "The meal was logged, but food history could not be saved." : error.localizedDescription
            showError = true
        }
    }

    private func finish() {
        isShowing = false
        if let onLogged { onLogged(selection) }
        else { rootIsActive = false }
    }
}

/// Keeps adding a food and revising a logged portion visually and behaviorally consistent.
struct ServingPage: View {
    let name: String
    @Binding var meal: EatingTime
    @Binding var input: PortionInput
    private var portion: FoodPortion { input.portion }
    let calories: String
    let carbs: String
    let protein: String
    let fat: String
    let actionTitle: String
    let canSave: Bool
    let save: () -> Void
    @State private var showingPackage = false
    var preserveAmountOnSetup = false
    var sourceName: String?
    var sourceURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                JournalHeading(title: name, subtitle: "1 serving = \(portion.description(servings: 1))")
                VStack(alignment: .leading, spacing: 14) {
                    Text("Meal").font(.headline)
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description) }
                    }.pickerStyle(.segmented)
                    Divider()
                    HStack {
                        Text("Portion").font(.system(.title2, design: .serif))
                        Spacer()
                        if portion.metricAmount != nil {
                            Button(portion.itemCount == nil ? "Set package portion" : "Edit package portion") {
                                showingPackage = true
                            }.font(.subheadline)
                        }
                    }
                    if input.availableUnits.count > 1 {
                        let picker = Picker("Measure by", selection: Binding(get: { input.unit }, set: { input.select($0) })) {
                            ForEach(input.availableUnits, id: \.self) { Text(input.label(for: $0)).tag($0) }
                        }
                        if input.availableUnits.count <= 3 { picker.pickerStyle(.segmented) }
                        else { LabeledContent("Measure by") { picker.pickerStyle(.menu) } }
                    }
                    HStack {
                        Text(quantityLabel)
                        Spacer()
                        TextField("Quantity", text: $input.text)
                            .accessibilityLabel(quantityLabel)
                            .keyboardType(.numbersAndPunctuation).multilineTextAlignment(.center)
                            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { event in
                                guard let field = event.object as? UITextField, field.keyboardType == .numbersAndPunctuation else { return }
                                // Let the tap place its caret first, then select the prefilled amount for replacement.
                                DispatchQueue.main.async {
                                    if field.isFirstResponder { field.selectAll(nil) }
                                }
                            }
                            .frame(width: 88, height: 44)
                            .background(WarmInk.apricot.opacity(0.22), in: Capsule())
                    }
                    if let servings = input.servings, input.unit == .items {
                        Text("\(servings.formatted()) \(servings == 1 ? "serving" : "servings")")
                            .font(.subheadline).foregroundStyle(WarmInk.muted)
                    } else if let servings = input.servings, input.unit == .grams || servings != 1 {
                        Text(portion.description(servings: servings))
                            .font(.subheadline).foregroundStyle(WarmInk.muted)
                    }
                    Divider()
                    HStack(alignment: .firstTextBaseline) {
                        Text("Total").font(.system(.title2, design: .serif))
                        Spacer()
                        Text("\(calories) kcal").font(.system(.title, design: .serif))
                    }
                    HStack {
                        nutrient("Carbs", carbs)
                        nutrient("Protein", protein)
                        nutrient("Fat", fat)
                    }
                    if let sourceName, let sourceURL {
                        Link("Nutrition source · " + sourceName, destination: sourceURL).font(.footnote)
                    } else if let sourceName {
                        Text(sourceName).font(.footnote).foregroundStyle(WarmInk.muted)
                    }
                }.padding(22)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            Button(actionTitle, action: save).buttonStyle(JournalActionStyle()).disabled(!canSave)
                .padding(.horizontal, 22).padding(.vertical, 8).background(WarmInk.paper)
        }
        .journalPage()
        .sheet(isPresented: $showingPackage) {
            if let metric = portion.metricAmount {
                PackagePortionSheet(name: name, portion: portion, metric: metric.unit) { updated in
                    let oldServings = input.servings
                    let scale = updated.scale(relativeTo: portion) ?? 1
                    let servings = preserveAmountOnSetup ? (oldServings ?? 1) / scale : 1
                    input = PortionInput(portion: updated, savedQuantity: servings)
                }
            }
        }
    }

    private var quantityLabel: String {
        input.label(for: input.unit)
    }

    private func nutrient(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(WarmInk.muted)
            Text(value == "—" ? value : "\(value) g").font(.headline.monospacedDigit())
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PackagePortionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let name: String
    let metric: String
    let apply: (FoodPortion) -> Void
    @State private var count: String
    @State private var amount: String
    @State private var noun: String

    init(name: String, portion: FoodPortion, metric: String, apply: @escaping (FoodPortion) -> Void) {
        self.name = name
        self.metric = metric
        self.apply = apply
        let existing = portion.itemCount
        _noun = State(initialValue: existing?.plural ?? FoodPortion.suggestedNoun(for: name))
        _count = State(initialValue: existing?.perServing.formatted(.number.grouping(.never)) ?? "")
        _amount = State(initialValue: existing == nil ? "" : portion.metricAmount?.value.formatted(.number.grouping(.never)) ?? "")
    }

    private var updated: FoodPortion? {
        guard let count = PortionInput.decimal(count), let amount = PortionInput.decimal(amount) else { return nil }
        return .package(count: count, noun: noun, amount: amount, unit: metric)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    JournalHeading(title: "Package portion", subtitle: name)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Enter the item count and total \(metric == "g" ? "weight" : "volume") for one serving on your package.")
                        Picker("Count as", selection: $noun) {
                            ForEach(FoodPortion.packageNouns, id: \.self) { Text($0.capitalized).tag($0) }
                        }.pickerStyle(.menu)
                        TextField("\(noun.capitalized) per serving", text: $count)
                            .textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                        TextField("Total \(metric) per serving", text: $amount)
                            .textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                        if let updated { Text(updated.description(servings: 1)).foregroundStyle(WarmInk.muted) }
                    }.padding(.horizontal, 22)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Use package portion") {
                    if let updated { apply(updated); dismiss() }
                }.buttonStyle(JournalActionStyle()).disabled(updated == nil).padding(.horizontal, 22)
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .journalPage()
        }
    }
}

struct NutritionLabelScanView: View {
    let manager: FastingManager

    var body: some View {
        BarcodeEditorView(mode: .label, digits: "", initial: nil, manager: manager) { _ in }
    }
}

private enum BarcodeEditor: Int, Identifiable {
    case search, label, personal
    var id: Self { self }
}

private struct BarcodeEditorView: View {
    let mode: BarcodeEditor
    let digits: String
    let save: (SavedFood) throws -> Void
    let manager: FastingManager?
    @State private var confirmingPortion = false
    @State private var labelReading = false
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var brand: String
    @State private var serving: String
    @State private var metricSize: String
    @State private var metricUnit: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String
    @State private var otherNutrients: [Int: String]
    @State private var showOtherNutrients = false
    @FocusState private var focusedField: String?
    @State private var query = ""
    @StateObject private var groceries = GroceryNameSearch()
    @State private var selected: SavedFood?
    @State private var selectedID: FoodLookup?
    @State private var searchError: String?

    init(mode: BarcodeEditor, digits: String, initial: SavedFood?, manager: FastingManager? = nil, save: @escaping (SavedFood) throws -> Void) {
        self.mode = mode
        self.manager = manager
        self.digits = digits
        self.save = save
        _name = State(initialValue: initial?.name ?? "")
        _brand = State(initialValue: initial?.brand ?? "")
        _serving = State(initialValue: initial?.householdServing ?? "")
        let metric = initial?.portion.metricAmount
        _metricUnit = State(initialValue: metric?.unit ?? "g")
        _metricSize = State(initialValue: metric.map { Self.formatted($0.value) } ?? "")
        func nutrient(_ id: Int) -> String { initial?.nutrients[id].map(Self.formatted) ?? "" }
        _calories = State(initialValue: nutrient(208))
        _protein = State(initialValue: nutrient(203))
        _carbs = State(initialValue: nutrient(205))
        _fat = State(initialValue: nutrient(204))
        _otherNutrients = State(initialValue: Dictionary(uniqueKeysWithValues: Self.extraFields.map { ($0.id, nutrient($0.id)) }))
    }

    private static let extraFields: [(id: Int, title: String)] = [
        (291, "Dietary fiber (g)"), (269, "Total sugars (g)"), (606, "Saturated fat (g)"),
        (307, "Sodium (mg)"), (601, "Cholesterol (mg)")
    ]

    private static func formatted(_ value: Double) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...4)))
    }

    private func value(_ text: String) -> Double? {
        guard let value = PortionInput.decimal(text), value.isFinite, value >= 0, value < 1_000_000 else { return nil }
        return value
    }

    private var label: SavedFood? {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let energy = value(calories) else { return nil }
        let size = value(metricSize)
        if mode == .personal && serving.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && size == nil { return nil }
        guard metricSize.isEmpty || (size ?? 0) > 0 else { return nil }
        var nutrients = [208: energy]
        var entered = otherNutrients
        entered[203] = protein
        entered[204] = fat
        entered[205] = carbs
        for (id, field) in entered where !field.isEmpty {
            guard let grams = value(field) else { return nil }
            nutrients[id] = grams
        }
        return SavedFood(name: title, brand: brand.isEmpty ? nil : brand, servingQuantity: size ?? 1,
                         servingUnit: size == nil ? "serving" : metricUnit,
                         servingGrams: metricUnit == "g" ? size : nil, nutrients: nutrients,
                         householdServing: serving.isEmpty ? nil : serving, sourceName: mode == .personal ? "My food" : "My package label")
    }

    var body: some View {
        NavigationStack {
            Form {
                if mode != .search {
                    if mode == .label {
                        NutritionLabelCapture(reading: $labelReading) { reading in
                            calories = reading.calories ?? ""
                            protein = reading.protein ?? ""
                            carbs = reading.carbs ?? ""
                            fat = reading.fat ?? ""
                            serving = reading.serving ?? ""
                            metricSize = reading.metricSize ?? ""
                            metricUnit = reading.metricUnit
                            otherNutrients = reading.otherNutrients
                            showOtherNutrients = !otherNutrients.isEmpty
                        }
                    }
                    Section(mode == .personal ? "Food and serving" : "Package") {
                        TextField("Food name", text: $name).focused($focusedField, equals: "name")
                        TextField("Brand (optional)", text: $brand).focused($focusedField, equals: "brand")
                        TextField(mode == .personal ? "Serving, e.g. 1 bowl" : "Serving description, e.g. 1 cup", text: $serving).focused($focusedField, equals: "serving")
                        HStack {
                            TextField("Serving size (optional)", text: $metricSize).focused($focusedField, equals: "metricSize").keyboardType(.decimalPad)
                            Picker("Unit", selection: $metricUnit) { Text("g").tag("g"); Text("mL").tag("mL") }
                                .pickerStyle(.segmented).frame(width: 96)
                        }
                    }
                    Section("Nutrition per serving") {
                        field("Calories (kcal)", text: $calories)
                        field("Protein (g)", text: $protein)
                        field("Carbs (g)", text: $carbs)
                        field("Fat (g)", text: $fat)
                        DisclosureGroup("More nutrients", isExpanded: $showOtherNutrients) {
                            ForEach(Self.extraFields, id: \.id) { item in
                                field(item.title, text: Binding(get: { otherNutrients[item.id] ?? "" },
                                                               set: { otherNutrients[item.id] = $0 }))
                            }
                        }
                    }
                } else {
                    Section("Search foods") {
                        TextField("Food or brand name", text: $query).focused($focusedField, equals: "query")
                        if !query.isEmpty && !groceries.status.isEmpty { Text(groceries.status).font(.footnote) }
                        ForEach(groceries.matches) { match in
                            Button { if selectedID != match.id { selected = nil; selectedID = match.id } } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(match.name)
                                        Text(match.subtitle).font(.caption).foregroundStyle(WarmInk.muted)
                                    }
                                    Spacer()
                                    if selectedID == match.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    }
                }
                if let searchError { Text(searchError).foregroundStyle(WarmInk.action) }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 6) {
                    if focusedField != nil {
                        Button("Done typing") { focusedField = nil }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if mode == .search, let selected {
                        Text("\(selected.name) · \(Int((selected.nutrients[208] ?? 0).rounded())) kcal / \(selected.portion.description(servings: 1))")
                            .font(.footnote).lineLimit(3)
                    }
                    if !digits.isEmpty { Text(digits).font(.caption.monospacedDigit()).foregroundStyle(WarmInk.muted) }
                    Button(mode == .personal ? "Save food" : manager == nil ? "Save for this barcode" : "Choose portion") {
                        guard let food = mode == .search ? selected : label else { return }
                        if manager != nil { focusedField = nil; confirmingPortion = true }
                        else {
                            do { try save(food) } catch { searchError = error.localizedDescription }
                        }
                    }.buttonStyle(JournalActionStyle()).disabled(labelReading || (mode == .search ? selected : label) == nil)
                }.padding(.horizontal, 20).padding(.vertical, 8).background(WarmInk.paper)
            }
            .navigationDestination(isPresented: $confirmingPortion) {
                if let manager, let label {
                    FoodServingView(fastingManager: manager, isShowing: $confirmingPortion,
                                    rootIsActive: .constant(true), selection: .current, food: label, onLogged: { _ in dismiss() })
                }
            }
            .navigationTitle(mode == .personal ? "Create food" : mode == .search ? "Match a food" : manager == nil ? "Package label" : "Scan label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .task(id: query) {
                guard mode == .search else { return }
                selectedID = nil; selected = nil; searchError = nil
                await groceries.search(query.trimmingCharacters(in: .whitespacesAndNewlines),
                                      excludingBarcode: FoodLookup.barcode(digits, compressed: false).barcodeKey)
            }
            .task(id: selectedID) {
                selected = nil
                guard let id = selectedID else { return }
                do {
                    let food = try await FoodDataCentral().product(for: id)
                    try Task.checkCancellation()
                    selected = food
                    searchError = nil
                } catch { if !Task.isCancelled { searchError = error.localizedDescription } }
            }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title == "Calories (kcal)" ? "Required" : "Optional", text: text)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                .frame(width: 96, height: 32).accessibilityLabel(title)
                .focused($focusedField, equals: title)
        }
    }
}

struct PersonalFoodEditorView: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: ((SavedFood) -> Void)? = nil

    var body: some View {
        BarcodeEditorView(mode: .personal, digits: "", initial: nil) { food in
            try FavoriteFoods.shared.savePersonal(food)
            dismiss()
            onSave?(food)
        }
    }
}

struct FavoriteFood: Codable, Identifiable {
    let id: UUID
    let food: SavedFood
    let portion: FoodPortion
    let quantity: Double
    let inGrams: Bool
    var personal: Bool? = nil
    var pinned: Bool? = nil

    var input: PortionInput {
        PortionInput(portion: portion, savedQuantity: quantity, savedAsGrams: inGrams)
    }

    var portionLabel: String { portion.description(quantity: quantity, measuredInGrams: inGrams) }

    var caloriesLabel: String? {
        guard let servings = input.servings, let calories = food.using(portion).nutrients[208] else { return nil }
        return (servings * calories).formatted(.number.precision(.fractionLength(0))) + " kcal"
    }

    func matches(search: String) -> Bool {
        let title = [food.name, food.brand].compactMap { $0 }.joined(separator: " ")
        return search.split(whereSeparator: \.isWhitespace).allSatisfy { title.localizedStandardContains(String($0)) }
    }

    func matches(_ other: SavedFood) -> Bool {
        if let id = food.fdcID, let otherID = other.fdcID { return id == otherID }
        return food == other || food.using(portion) == other
    }
}

/// Keeps favorites independent of the recent-food list, including its legacy entries.
@MainActor
final class FavoriteFoods: ObservableObject {
    static let shared = FavoriteFoods()
    @Published private var records: [FavoriteFood]
    var entries: [FavoriteFood] { records.filter { $0.pinned != false } }
    var personalFoods: [FavoriteFood] { records.filter { $0.personal == true } }
    var backupRecords: [FavoriteFood] { records }
    private let url: URL
    private var loaded: Bool

    init(url: URL = URL.applicationSupportDirectory.appendingPathComponent("FavoriteFoods.json")) {
        self.url = url
        do {
            records = try JSONDecoder().decode([FavoriteFood].self, from: Data(contentsOf: url))
            loaded = true
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            records = []
            loaded = true
        } catch {
            records = []
            loaded = false
        }
    }

    func save(_ food: SavedFood, input: PortionInput) throws {
        guard let quantity = input.savedQuantity, input.servings != nil else { return }
        try loadIfNeeded()
        let previous = records.first { $0.matches(food) }
        let id = previous?.id ?? UUID()
        let entry = FavoriteFood(id: id, food: food, portion: input.portion, quantity: quantity,
                                 inGrams: input.savedUnit == .gram, personal: previous?.personal, pinned: true)
        try store([entry] + records.filter { $0.id != id })
    }

    func remove(_ id: UUID) throws {
        try loadIfNeeded()
        if let index = records.firstIndex(where: { $0.id == id && $0.personal == true }) {
            var updated = records
            updated[index].pinned = false
            try store(updated)
        } else {
            try store(records.filter { $0.id != id })
        }
    }

    func savePersonal(_ food: SavedFood) throws {
        try loadIfNeeded()
        let id = records.first { $0.matches(food) }?.id ?? UUID()
        let entry = FavoriteFood(id: id, food: food, portion: food.portion, quantity: 1,
                                 inGrams: false, personal: true, pinned: true)
        try store([entry] + records.filter { $0.id != id })
    }

    func deletePersonal(_ id: UUID) throws {
        try loadIfNeeded()
        try store(records.filter { !($0.id == id && $0.personal == true) })
    }

    func restoreMissing(_ incoming: [FavoriteFood]) throws -> Int {
        try loadIfNeeded()
        var merged = records
        var ids = Set(records.map(\.id))
        var byName = Dictionary(grouping: records, by: { $0.food.name })
        var fdcIDs = Set(records.compactMap { $0.food.fdcID })
        for item in incoming {
            guard !ids.contains(item.id), !(item.food.fdcID.map(fdcIDs.contains) ?? false),
                  !(byName[item.food.name] ?? []).contains(where: { $0.matches(item.food) }) else { continue }
            merged.append(item)
            ids.insert(item.id)
            if let id = item.food.fdcID { fdcIDs.insert(id) }
            byName[item.food.name, default: []].append(item)
        }
        let added = merged.count - records.count
        if added > 0 { try store(merged) }
        return added
    }

    func loadIfNeeded() throws {
        guard !loaded else { return }
        records = try JSONDecoder().decode([FavoriteFood].self, from: Data(contentsOf: url))
        loaded = true
    }

    private func store(_ next: [FavoriteFood]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(next).write(to: url, options: .atomic)
        records = next
    }
}
