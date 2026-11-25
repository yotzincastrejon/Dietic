import SwiftUI

private func menuResource<T: Decodable>(_ name: String) throws -> T {
    guard let url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "RestaurantMenus") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
}

private func searchKey(_ text: String) -> String {
    text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
        .filter { $0.isLetter || $0.isNumber }
}

struct Restaurant: Decodable, Identifiable {
    let id: String
    let name: String
    let count: Int
    let source: String
    let url: URL
    let note: String?

    static let directory: [Self] = (try? menuResource("index")) ?? []

    static let brandNames = Set(directory.map(\.name))

    private var searchNames: [String] {
        var names = [searchKey(name), searchKey(id)]
        switch id {
        case "kfc": names.append("kentuckyfriedchicken")
        case "dairy-queen": names.append("dq")
        case "jersey-mike-s-subs": names.append("jerseymikes")
        case "mcalister-s-deli": names.append("mcalisters")
        case "freddy-s-frozen-custard-steakburgers": names.append("freddys")
        case "panera-bread": names.append("panera")
        case "in-n-out-burger": names.append("innout")
        default: break
        }
        return names
    }

    func matches(_ search: String) -> Bool {
        let key = searchKey(search)
        return !key.isEmpty && (searchNames.contains { $0.contains(key) } || menuQuery(for: search) != nil)
    }

    // A brand query can include an item. Match whole leading words before carrying the rest into the menu.
    func menuQuery(for search: String) -> String? {
        let words = search.split(whereSeparator: \.isWhitespace)
        let keys = searchNames
        for end in words.indices.reversed() {
            let prefix = searchKey(words[...end].joined())
            if keys.contains(prefix) { return words.dropFirst(end + 1).joined(separator: " ") }
        }
        return nil
    }
}

private struct MenuPortion: Decodable, Hashable {
    let name: String
    let size: String?
    let portion: String?
    let nutrients: [Int: Double]
    let year: Int?
    let link: URL?

    var label: String {
        [size, portion].compactMap { $0 }.reduce(into: [String]()) { parts, value in
            if !parts.contains(value) { parts.append(value) }
        }.joined(separator: " · ")
    }

    func food(at chain: Restaurant) -> SavedFood {
        let text = portion?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let numeric = text.prefix { $0.isNumber || $0 == "." }
        let unit = text.dropFirst(numeric.count).trimmingCharacters(in: .whitespaces)
        let quantity = Double(numeric)
        let simple = quantity.map { $0 > 0 } == true && !unit.isEmpty
        let source = link ?? chain.url
        let provider: String
        switch source.host {
        case "fastfuel-b.pages.dev", "fastfuel-c.pages.dev", "tryfastfuel.com": provider = "FastFuel"
        case "fastfoodcalc.com": provider = "Fast Food Calc"
        default: provider = chain.name
        }
        let serving = simple ? unit : (text.isEmpty || text == size ? "menu portion" : "serving (\(text))")
        return SavedFood(name: size.map { "\(name) (\($0))" } ?? name, brand: chain.name,
                         servingQuantity: simple ? (quantity ?? 1) : 1, servingUnit: serving,
                         servingGrams: simple && FoodPortion.metricUnit(unit) == "g" ? quantity : nil,
                         nutrients: nutrients, sourceName: [provider, year.map(String.init)].compactMap { $0 }.joined(separator: " · "),
                         sourceURL: source)
    }
}

private struct MenuItem: Identifiable {
    let name: String
    let portions: [MenuPortion]
    let filterKey: String
    var id: String { name }

    static func load(_ chain: Restaurant) throws -> [MenuItem] {
        let rows: [MenuPortion] = try menuResource(chain.id)
        let sizes = ["Extra Small", "Small", "Medium", "Large", "Extra Large", "XL"]
        return Dictionary(grouping: rows, by: \.name).map { name, portions in
            let sorted = portions.sorted {
                let lhs = sizes.firstIndex(of: $0.size ?? "") ?? sizes.count
                let rhs = sizes.firstIndex(of: $1.size ?? "") ?? sizes.count
                return lhs == rhs ? $0.label.localizedStandardCompare($1.label) == .orderedAscending : lhs < rhs
            }
            return MenuItem(name: name, portions: sorted,
                            filterKey: searchKey(name + " " + sorted.map(\.label).joined(separator: " ")))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

private struct MenuFilters: Equatable {
    enum Order: String, CaseIterable {
        case name = "Menu name", calories = "Lowest calories", protein = "Most protein"
    }
    var order = Order.name
    var maxCalories = ""
    var minProtein = ""
    var maxSodium = ""

    var valid: Bool {
        [maxCalories, minProtein, maxSodium].allSatisfy {
            $0.trimmingCharacters(in: .whitespaces).isEmpty || PortionInput.decimal($0) != nil
        }
    }

    func apply(to items: [MenuItem], search: String) -> [MenuItem] {
        let key = searchKey(search)
        let calorieLimit = PortionInput.decimal(maxCalories)
        let proteinFloor = PortionInput.decimal(minProtein)
        let sodiumLimit = PortionInput.decimal(maxSodium)
        func rank(_ portion: MenuPortion) -> Double {
            switch order {
            case .name: return 0
            case .calories: return portion.nutrients[208] ?? .infinity
            case .protein: return portion.nutrients[203].map { -$0 } ?? .infinity
            }
        }
        var result: [MenuItem] = []
        for item in items where key.isEmpty || item.filterKey.contains(key) {
            var portions = item.portions.filter { p in
                if let calorieLimit, !(p.nutrients[208].map { $0 <= calorieLimit } ?? false) { return false }
                if let proteinFloor, !(p.nutrients[203].map { $0 >= proteinFloor } ?? false) { return false }
                if let sodiumLimit, !(p.nutrients[307].map { $0 <= sodiumLimit } ?? false) { return false }
                return true
            }
            guard !portions.isEmpty else { continue }
            if order != .name { portions.sort { rank($0) < rank($1) } }
            result.append(MenuItem(name: item.name, portions: portions, filterKey: item.filterKey))
        }
        if order != .name {
            result.sort { a, b in
                let lhs = a.portions.first.map(rank) ?? .infinity
                let rhs = b.portions.first.map(rank) ?? .infinity
                return lhs == rhs ? a.name.localizedStandardCompare(b.name) == .orderedAscending : lhs < rhs
            }
        }
        return result
    }
}

private struct RestaurantFilterView: View {
    @Environment(\.dismiss) private var dismiss
    @State var filters: MenuFilters
    let apply: (MenuFilters) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Picker("Sort by", selection: $filters.order) {
                    ForEach(MenuFilters.Order.allCases, id: \.self) { Text($0.rawValue) }
                }
                Section {
                    field("Maximum calories", "kcal", $filters.maxCalories)
                    field("Minimum protein", "g", $filters.minProtein)
                    field("Maximum sodium", "mg", $filters.maxSodium)
                } header: { Text("Per menu portion") }
                  footer: { Text("Leave a field blank to include all values. A filter includes only portions with that nutrient listed.") }
                Button("Reset filters") { filters = MenuFilters() }
            }
            .navigationTitle("Menu filters")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Apply") { apply(filters); dismiss() }.disabled(!filters.valid) }
            }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func field(_ title: String, _ unit: String, _ text: Binding<String>) -> some View {
        HStack {
            Text(title)
            TextField("Any", text: text).multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad).accessibilityLabel(title)
            Text(unit).foregroundStyle(WarmInk.muted)
        }
    }
}

struct RestaurantMenu: View {
    let chain: Restaurant
    @ObservedObject var fastingManager: FastingManager
    @Environment(\.managedObjectContext) private var context
    @State private var meal: EatingTime
    @State private var pending = Set<MenuPortion>()
    @State private var order: [HKSampleWithDescription] = []
    @State private var undoing = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Binding var rootIsActive: Bool
    @State private var search: String
    @State private var items: [MenuItem] = []
    @State private var filters = MenuFilters()
    @State private var choosingFilters = false
    @State private var loadError = false
    @State private var expanded: String?
    @State private var selected: SavedFood?
    @State private var showingFood = false

    init(chain: Restaurant, query: String, manager: FastingManager, meal: EatingTime, root: Binding<Bool>) {
        self.chain = chain
        fastingManager = manager
        _meal = State(initialValue: meal)
        _rootIsActive = root
        _search = State(initialValue: query)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JournalHeading(title: chain.name, subtitle: chain.note)
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search this menu", text: $search).autocorrectionDisabled().submitLabel(.search)
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Clear menu search")
                }
                Button { choosingFilters = true } label: {
                    Image(systemName: filters == MenuFilters() ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                        .font(.title3).frame(width: 44, height: 44)
                }.accessibilityLabel("Menu filters")
            }.padding(.horizontal, 14).frame(minHeight: 48)
                .background(WarmInk.apricot.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 22).padding(.vertical, 12)
            let matches = filters.apply(to: items, search: search)
            List {
                Section {
                    if loadError { Text("This menu could not be loaded.") }
                    else if items.isEmpty { ProgressView("Loading menu…") }
                    else if matches.isEmpty { Text("No matching menu items.") }
                    ForEach(matches) { item in
                        if item.portions.count == 1, let portion = item.portions.first {
                            portionButton(portion, title: item.name, subtitle: portion.label)
                        } else {
                            DisclosureGroup(isExpanded: Binding(get: { expanded == item.id }, set: { expanded = $0 ? item.id : nil })) {
                                ForEach(item.portions.indices, id: \.self) { index in
                                    let portion = item.portions[index]
                                    portionButton(portion, title: portion.label.isEmpty ? "Standard" : portion.label, subtitle: "")
                                }
                            } label: { Text(item.name).font(.headline) }
                        }
                    }
                } footer: {
                    Link("Nutrition data · \(chain.source)", destination: chain.url)
                }.listRowBackground(WarmInk.paper)
            }.listStyle(.plain).scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            HStack {
                Menu {
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description).tag($0) }
                    }
                } label: {
                    Label(meal.description, systemImage: "chevron.up.chevron.down")
                        .frame(minHeight: 44)
                }.accessibilityLabel("Meal, " + meal.description)
                Spacer()
                if let last = order.last {
                    Menu {
                        if order.allSatisfy({ $0.attrIDArray.contains(208) }) {
                            Text("\(order.reduce(0) { $0 + $1.calories }.formatted(.number.precision(.fractionLength(0)))) kcal added")
                        }
                        if order.allSatisfy({ $0.attrIDArray.contains(203) }) {
                            Text("\(order.reduce(0) { $0 + $1.protein }.formatted(.number.precision(.fractionLength(0...1)))) g protein added")
                        }
                        Button("Undo " + last.foodName) {
                            guard !undoing else { return }
                            undoing = true
                            Task { await undo(last) }
                        }
                    } label: {
                        Label(order.count == 1 ? "1 item added" : "\(order.count) items added", systemImage: "chevron.down")
                            .font(.subheadline).lineLimit(1)
                    }.disabled(undoing || !pending.isEmpty)
                }
                Button("Done") { rootIsActive = false }
                    .buttonStyle(.borderedProminent).clipShape(Capsule()).disabled(!pending.isEmpty || undoing)
            }.padding(.horizontal, 22).padding(.vertical, 4).background(WarmInk.paper)
        }
        .journalPage()
        .sheet(isPresented: $choosingFilters) {
            RestaurantFilterView(filters: filters) { filters = $0; expanded = nil }
        }
        .alert("Meal log", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
        .task(id: chain.id) {
            do { items = try await Task.detached { try MenuItem.load(chain) }.value }
            catch { loadError = true }
        }
        .navigationDestination(isPresented: $showingFood) {
            if let selected {
                FoodServingView(fastingManager: fastingManager, isShowing: $showingFood, rootIsActive: $rootIsActive,
                                selection: meal, food: selected, onEntryLogged: { order.append($0) }, onLogged: { meal = $0 })
            }
        }
    }

    private func portionButton(_ portion: MenuPortion, title: String, subtitle: String) -> some View {
        HStack(spacing: 6) {
            Button {
                selected = portion.food(at: chain)
                showingFood = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title).font(.headline)
                        if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(WarmInk.muted) }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if let energy = portion.nutrients[208] { Text("\(energy.formatted()) kcal") }
                        if let protein = portion.nutrients[203] { Text("\(protein.formatted()) g protein") }
                    }.font(.caption.monospacedDigit()).foregroundStyle(WarmInk.muted)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button {
                guard pending.insert(portion).inserted else { return }
                let target = meal
                let date = fastingManager.mealTimestamp
                Task { await add(portion, to: target, date: date) }
            } label: {
                ZStack {
                    Circle().fill(WarmInk.action).frame(width: 30, height: 30)
                    if pending.contains(portion) { ProgressView().tint(WarmInk.paper) }
                    else { Image(systemName: "plus").font(.body.weight(.semibold)).foregroundStyle(WarmInk.paper) }
                }.frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(pending.contains(portion))
            .accessibilityLabel(["Add", portion.name, portion.label, "to", meal.description].filter { !$0.isEmpty }.joined(separator: " "))
        }
    }

    @MainActor private func undo(_ entry: HKSampleWithDescription) async {
        defer { undoing = false }
        do {
            try await fastingManager.removeDiaryEntry(id: entry.uuid)
            order.removeAll { $0.uuid == entry.uuid }
            UIAccessibility.post(notification: .announcement, argument: entry.foodName + " removed")
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    @MainActor
    private func add(_ portion: MenuPortion, to meal: EatingTime, date: Date) async {
        defer { pending.remove(portion) }
        let food = portion.food(at: chain)
        let sample = food.sample(multiplier: 1, quantity: 1, unit: .serving, meal: meal, date: date)
        do {
            try await fastingManager.saveMeal(sample)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            return
        }
        order.append(sample)
        UIAccessibility.post(notification: .announcement, argument: "\(food.name) added to \(meal.description)")
        do { try food.recordHistory(in: context) }
        catch {
            errorMessage = "The meal was logged, but food history could not be saved."
            showError = true
        }
    }
}
