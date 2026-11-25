import SwiftUI
import CodeScanner
import CoreData

struct AddMoreFoodView: View {
    @ObservedObject var fastingManager: FastingManager
    let mealPeriod: EatingTime
    @Binding var rootIsActive: Bool
    var scan = false

    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SearchedFoods.timestamp, ascending: false)])
    private var history: FetchedResults<SearchedFoods>
    @ObservedObject private var favorites = FavoriteFoods.shared
    @State private var favoriteInput: PortionInput?
    @State private var search = ""
    @State private var restaurantsOnly = false
    @StateObject private var groceries = GroceryNameSearch()
    @State private var lookup: FoodLookup?
    @State private var historyFood: SavedFood?
    @State private var historyItem: SearchedFoods?
    @State private var showingFood = false
    @State private var torch = false
    @State private var scanError: String?
    @State private var historyError = ""
    @State private var showHistoryError = false

    private var query: String { search.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var matchingFavorites: [FavoriteFood] {
        favorites.entries.filter { $0.matches(search: query) }
    }

    private var otherPersonalMatches: [FavoriteFood] {
        guard !query.isEmpty else { return [] }
        return favorites.personalFoods.filter { $0.pinned == false && $0.matches(search: query) }
    }

    private var matchingRestaurants: [Restaurant] {
        Restaurant.directory.filter { (restaurantsOnly && query.isEmpty) || $0.matches(query) }
    }

    private var typedFood: String { scan || restaurantsOnly ? "" : query }

    private var groceryQuery: String {
        guard !scan, !restaurantsOnly, !query.isEmpty else { return "" }
        // A recognized chain belongs in its own menu. Partial matches can coexist with groceries.
        let namedChain = matchingRestaurants.contains { $0.menuQuery(for: query) != nil }
        return namedChain ? "" : query
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            JournalHeading(title: scan ? "Scan barcode" : "Log food")
            VStack(alignment: .leading, spacing: 14) {
                if scan {
                    if !showingFood && scanError == nil {
                        CodeScannerView(codeTypes: [.ean13, .ean8, .upce, .itf14, .code128, .code39, .code39Mod43,
                                                    .code93, .interleaved2of5, .pdf417], showViewfinder: true,
                                        simulatedData: "0049000061062", isTorchOn: torch) { result in
                            switch result {
                            case .success(let code):
                                guard !showingFood else { return }
                                open(.barcode(code.string, compressed: code.type == .upce))
                            case .failure:
                                scanError = "Check camera access for Dietic in Settings, or enter the barcode below."
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .bottomTrailing) {
                            Button { torch.toggle() } label: {
                                Image(systemName: torch ? "flashlight.on.fill" : "flashlight.off.fill")
                                    .frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
                            }.padding().accessibilityLabel(torch ? "Turn flashlight off" : "Turn flashlight on")
                        }
                    } else if let scanError {
                        Text(scanError).font(.callout)
                        Button("Try camera again") { self.scanError = nil }
                    }
                    HStack {
                        TextField("Barcode digits", text: $search).keyboardType(.numberPad)
                        Button("Look up") { open(.barcode(query, compressed: false)) }
                            .disabled(![8, 12, 13, 14].contains(query.count) || !query.allSatisfy({ $0.isASCII && $0.isNumber }))
                    }.padding(.horizontal, 14).frame(minHeight: 48)
                        .background(WarmInk.apricot.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    Picker("Search in", selection: $restaurantsOnly) {
                        Text("Foods").tag(false)
                        Text("Restaurants").tag(true)
                    }.pickerStyle(.segmented)
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField(restaurantsOnly ? "Find a restaurant" : "Find a food", text: $search).autocorrectionDisabled().submitLabel(.search)
                    }.padding(.horizontal, 14).frame(minHeight: 48)
                        .background(WarmInk.apricot.opacity(0.20), in: RoundedRectangle(cornerRadius: 12))
                    List {
                        if !restaurantsOnly && !matchingFavorites.isEmpty {
                            Section("Favorites") {
                                ForEach(matchingFavorites) { entry in
                                    savedPortionRow(entry).swipeActions {
                                        Button("Unfavorite", role: .destructive) {
                                            do { try favorites.remove(entry.id) }
                                            catch { historyError = error.localizedDescription; showHistoryError = true }
                                        }
                                    }
                                }
                            }.listRowBackground(WarmInk.paper)
                        }
                        if !restaurantsOnly && !otherPersonalMatches.isEmpty {
                            Section("Personal foods") {
                                ForEach(otherPersonalMatches) { savedPortionRow($0) }
                            }.listRowBackground(WarmInk.paper)
                        }
                        if !typedFood.isEmpty && groceries.matches.contains(where: { $0.isSaved }) {
                            Section("Your groceries") {
                                groceryRows(groceries.matches.filter { $0.isSaved })
                            }.listRowBackground(WarmInk.paper)
                        }
                        if restaurantsOnly || !matchingRestaurants.isEmpty {
                            Section("Restaurants") {
                                if matchingRestaurants.isEmpty {
                                    Text("No matching restaurants.").foregroundStyle(WarmInk.muted)
                                }
                                ForEach(matchingRestaurants) { chain in
                                    NavigationLink {
                                        RestaurantMenu(chain: chain, query: chain.menuQuery(for: query) ?? "",
                                                       manager: fastingManager, meal: mealPeriod, root: $rootIsActive)
                                    } label: {
                                        row(chain.name, "", nil)
                                    }.accessibilityIdentifier("restaurant-" + chain.id)
                                }
                            }.listRowBackground(WarmInk.paper)
                        }
                        if !restaurantsOnly && query.isEmpty {
                            Section("Recent foods") {
                                if history.isEmpty { Text("Search for a food to log your first meal.").foregroundStyle(WarmInk.muted) }
                                ForEach(history) { item in
                                    HStack {
                                        Button {
                                            guard let food = SavedFood.readHistory(item.jsonData) else {
                                                historyError = "This saved food could not be read."
                                                showHistoryError = true
                                                return
                                            }
                                            historyFood = food
                                            historyItem = item
                                            showingFood = true
                                        } label: {
                                            row(item.name ?? "Food", item.brandName ?? "", "\(Int(item.calories.rounded())) kcal")
                                        }
                                        PlusToCheckMark(fastingManager: fastingManager, mealPeriod: mealPeriod, fetched: item)
                                            .buttonStyle(.borderless).fixedSize()
                                            .accessibilityLabel("Add one serving to \(mealPeriod.description)")
                                    }
                                }
                                .onDelete { offsets in
                                    let deleted = offsets.map { history[$0] }
                                    deleted.forEach(context.delete)
                                    do { try context.save() }
                                    catch { context.rollback(); historyError = error.localizedDescription; showHistoryError = true }
                                }
                            }.listRowBackground(WarmInk.paper)
                        } else if !groceryQuery.isEmpty && (!groceries.status.isEmpty || groceries.matches.contains(where: { !$0.isSaved })) {
                            Section("Foods") {
                                if !groceries.status.isEmpty { Text(groceries.status).foregroundStyle(WarmInk.muted) }
                                groceryRows(groceries.matches.filter { !$0.isSaved })
                            }.listRowBackground(WarmInk.paper)
                        }
                    }.listStyle(.plain).scrollContentBackground(.hidden).scrollDismissesKeyboard(.interactively)
                }
                Spacer(minLength: 0)
            }.padding(.horizontal, 22).padding(.vertical, 14)
        }
        .journalPage()
        .task(id: typedFood) {
            await groceries.search(typedFood, online: !groceryQuery.isEmpty)
        }
        .navigationDestination(isPresented: $showingFood) {
            if let lookup {
                FoodLookupView(isShowing: $showingFood, rootIsActive: $rootIsActive, fastingManager: fastingManager,
                               lookup: lookup, mealPeriod: mealPeriod)
            } else if let historyFood {
                FoodServingView(fastingManager: fastingManager, isShowing: $showingFood, rootIsActive: $rootIsActive,
                                selection: mealPeriod, food: historyFood, historyItem: historyItem, initialInput: favoriteInput)
            }
        }
        .onChange(of: showingFood) { active in
            if !active { lookup = nil; historyFood = nil; historyItem = nil; favoriteInput = nil }
        }
        .task {
            do { try favorites.loadIfNeeded() }
            catch { historyError = error.localizedDescription; showHistoryError = true }
        }
        .alert("Saved foods", isPresented: $showHistoryError) { Button("OK") {} } message: { Text(historyError) }
    }

    private func savedPortionRow(_ entry: FavoriteFood) -> some View {
        HStack {
            Button {
                favoriteInput = entry.input
                historyFood = entry.food
                historyItem = nil
                showingFood = true
            } label: {
                row(entry.food.name, [entry.food.brand, entry.portionLabel].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "), entry.caloriesLabel)
            }.buttonStyle(.plain)
            SavedPortionAdd(food: entry.food.using(entry.portion), input: entry.input, manager: fastingManager, meal: mealPeriod)
        }
    }

    private func groceryRows(_ matches: [GroceryMatch]) -> some View {
        ForEach(matches) { match in
            Button { open(match.id) } label: {
                row(match.name, match.subtitle, match.energy)
            }
        }
    }

    private func open(_ value: FoodLookup) {
        lookup = value
        showingFood = true
    }

    private func row(_ name: String, _ subtitle: String, _ calories: String?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name).font(.headline)
                if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(WarmInk.muted) }
            }
            Spacer()
            if let calories { Text(calories).font(.caption.monospacedDigit()).foregroundStyle(WarmInk.muted) }
        }.frame(minHeight: 44).contentShape(Rectangle())
    }
}

private struct SavedPortionAdd: View {
    @Environment(\.managedObjectContext) private var viewContext
    let food: SavedFood
    let input: PortionInput
    let manager: FastingManager
    let meal: EatingTime

    @State private var saving = false
    @State private var added = false
    @State private var errorMessage: String?

    var body: some View {
        Button {
            guard !saving, !added, let multiplier = input.servings, let quantity = input.savedQuantity else { return }
            let sample = food.sample(multiplier: multiplier, quantity: quantity,
                                     unit: input.savedUnit, meal: meal, date: manager.mealTimestamp)
            saving = true
            Task {
                defer { saving = false }
                do {
                    try await manager.saveMeal(sample)
                    added = true
                    try food.recordHistory(in: viewContext)
                } catch {
                    errorMessage = added ? "The meal was logged, but recent foods could not be updated." : error.localizedDescription
                }
            }
        } label: {
            Image(systemName: added ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.title).foregroundStyle(WarmInk.action).frame(width: 44, height: 44)
        }
        .buttonStyle(.borderless).disabled(saving || added || input.servings == nil)
        .accessibilityLabel(added ? "Added \(food.name)" : "Add \(food.portion.description(servings: input.servings ?? 0)) of \(food.name) to \(meal.description)")
        .alert("Meal log", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}

struct PlusToCheckMark: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var fastingManager: FastingManager
    @State var mealPeriod: EatingTime
    @State var isTapped = false
    @State private var saving = false
    @State private var errorMessage = ""
    @State private var showError = false
    let fetched: SearchedFoods
    var body: some View {
        Button {
            guard !saving, !isTapped else { return }
            saving = true
            Task { await addServing() }
        } label: {
            Image(systemName: isTapped ? "checkmark" : "plus")
                .font(.body.weight(.semibold)).foregroundStyle(isTapped ? WarmInk.action : WarmInk.paper)
                .frame(width: 32, height: 32)
                .background(isTapped ? WarmInk.apricot.opacity(0.4) : WarmInk.action, in: Circle())
                .frame(width: 44, height: 44)
        }
        .disabled(saving || isTapped)
        .alert("Meal log", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
    }
    
    @MainActor private func addServing() async {
        defer { saving = false }
        guard let food = SavedFood.readHistory(fetched.jsonData) else {
            errorMessage = "This saved food could not be read."
            showError = true
            return
        }
        do {
            let sample = food.sample(multiplier: 1, quantity: 1, unit: .serving,
                                     meal: mealPeriod, date: fastingManager.mealTimestamp)
            try await fastingManager.saveMeal(sample)
            isTapped = true
            fetched.timestamp = Date()
            try viewContext.save()
        } catch {
            errorMessage = isTapped ? "The meal was logged, but food history could not be updated." : error.localizedDescription
            showError = true
        }
    }
}

struct GroceryLibraryView: View {
    let manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var entries: [String: BarcodeFoods.Entry] = [:]
    @State private var selected: String?
    @State private var detail = false
    @State private var removal: Removal?
    @ObservedObject private var favorites = FavoriteFoods.shared
    @State private var personalSelection: FavoriteFood?
    @State private var creating = false
    @State private var backup = false
    @State private var errorMessage: String?
    @State private var meal = EatingTime.current

    private enum Removal {
        case barcode(String, String)
        case personal(UUID, String)

        var title: String {
            switch self {
            case .barcode: return "Forget this barcode?"
            case .personal: return "Remove this personal food?"
            }
        }

        var message: String {
            switch self {
            case .barcode(_, let name): return "The next scan of \(name) will look up the barcode again."
            case .personal(_, let name): return "This removes \(name) from your saved foods and favorites."
            }
        }
    }

    private var matchingPersonalFoods: [FavoriteFood] {
        favorites.personalFoods.filter { $0.matches(search: query) }
    }

    private var matches: [String] {
        let words = query.split(whereSeparator: \.isWhitespace)
        let filtered = entries.filter { key, entry in
            let text = [entry.food.name, entry.food.brand, key].compactMap { $0 }.joined(separator: " ")
            return words.allSatisfy { text.localizedStandardContains(String($0)) }
        }
        return filtered.sorted {
            if $0.value.lastScan != $1.value.lastScan { return $0.value.lastScan > $1.value.lastScan }
            return $0.key < $1.key
        }.map(\.key)
    }

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty && favorites.personalFoods.isEmpty {
                    Text("Scan a grocery barcode or create a food to keep its nutrition here for offline logging.")
                        .foregroundStyle(WarmInk.muted)
                } else if matches.isEmpty && matchingPersonalFoods.isEmpty {
                    Text("No matching groceries.").foregroundStyle(WarmInk.muted)
                } else {
                    if !matchingPersonalFoods.isEmpty {
                        Section("Personal foods") {
                            ForEach(matchingPersonalFoods) { item in
                                HStack {
                                    Button {
                                        selected = nil
                                        personalSelection = item
                                        detail = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.food.name).font(.headline)
                                            Text(item.portionLabel).font(.caption).foregroundStyle(WarmInk.muted)
                                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                                    }.buttonStyle(.plain)
                                    SavedPortionAdd(food: item.food.using(item.portion), input: item.input, manager: manager, meal: meal).id(meal)
                                }.swipeActions {
                                    Button("Remove", role: .destructive) { removal = .personal(item.id, item.food.name) }
                                }
                            }
                        }.listRowBackground(WarmInk.paper)
                    }
                    ForEach(matches, id: \.self) { key in
                        if let entry = entries[key] {
                            HStack(spacing: 6) {
                                Button { personalSelection = nil; selected = key; detail = true } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.food.name).font(.headline)
                                        Text([entry.food.brand, entry.food.portion.description(servings: 1)]
                                            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                            .font(.subheadline).foregroundStyle(WarmInk.muted)
                                        if entry.scans > 0 {
                                            Text("\(entry.scans) \(entry.scans == 1 ? "scan" : "scans") · \(entry.lastScan.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption).foregroundStyle(WarmInk.muted)
                                        }
                                    }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                                }.buttonStyle(.plain)
                                SavedPortionAdd(food: entry.food, input: PortionInput(portion: entry.food.portion), manager: manager, meal: meal).id(meal)
                            }.swipeActions {
                                Button("Forget", role: .destructive) { removal = .barcode(key, entry.food.name) }
                            }
                        }
                    }.listRowBackground(WarmInk.paper)
                }
            }
            .searchable(text: $query, prompt: "Food, brand or barcode")
            .scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("My groceries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button { creating = true } label: { Label("Create food", systemImage: "plus") }
                    Button { backup = true } label: { Label("Back up groceries", systemImage: "externaldrive") }
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description).tag($0) }
                    }.pickerStyle(.menu)
                }
            }
            .navigationDestination(isPresented: $detail) {
                if let item = personalSelection {
                    FoodServingView(fastingManager: manager, isShowing: $detail, rootIsActive: .constant(true),
                                    selection: meal, food: item.food, initialInput: item.input, onLogged: { meal = $0 })
                } else if let selected, let entry = entries[selected] {
                    FoodServingView(fastingManager: manager, isShowing: $detail, rootIsActive: .constant(true),
                                    selection: meal, food: entry.food, barcodeKey: selected, onLogged: { meal = $0 })
                }
            }
            .sheet(isPresented: $creating) { PersonalFoodEditorView() }
            .sheet(isPresented: $backup) { GroceryBackupView() }
            .alert(removal?.title ?? "Remove food?", isPresented: Binding(get: { removal != nil }, set: { if !$0 { removal = nil } }),
                   presenting: removal) { action in
                switch action {
                case .barcode(let key, _):
                    Button("Forget saved match", role: .destructive) {
                        do { try BarcodeFoods.shared.forget(key) }
                        catch { errorMessage = error.localizedDescription }
                    }
                case .personal(let id, _):
                    Button("Remove personal food", role: .destructive) {
                        do { try favorites.deletePersonal(id) }
                        catch { errorMessage = error.localizedDescription }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { action in Text(action.message) }
            .alert("Saved groceries", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .onAppear {
                entries = BarcodeFoods.shared.entries
                do { try favorites.loadIfNeeded() }
                catch { errorMessage = error.localizedDescription }
            }
            .onReceive(BarcodeFoods.shared.changes) { entries = BarcodeFoods.shared.entries }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }
}
