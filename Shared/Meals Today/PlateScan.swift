import SwiftUI
import PhotosUI
import AVFoundation

private struct PlateItem: Identifiable {
    let id = UUID()
    let estimate: PlateEstimate
    var food: SavedFood?
    var input: PortionInput?
    var looking = true

    mutating func use(_ food: SavedFood) {
        self.food = food
        if let grams = estimate.grams, let servingWeight = food.portion.grams, servingWeight > 0 {
            input = PortionInput(portion: food.portion, savedQuantity: Double(grams), savedAsGrams: true)
        } else {
            input = PortionInput(portion: food.portion)
            // Ask for an amount when the image and database do not share a unit.
            if !estimate.name.isEmpty { input?.text = "" }
        }
        looking = false
    }

    var energy: Double? {
        guard let servings = input?.servings, let kcal = food?.nutrients[208],
              (servings * kcal).isFinite else { return nil }
        return servings * kcal
    }

    func sample(meal: EatingTime, date: Date) -> HKSampleWithDescription? {
        guard energy != nil, let input, let amount = input.savedQuantity,
              let multiplier = input.servings, let food else { return nil }
        return food.sample(multiplier: multiplier, quantity: amount, unit: input.savedUnit, meal: meal, date: date)
    }
}

private struct PlateSearchRequest: Identifiable {
    let id = UUID()
    let itemID: UUID?
    let query: String
}

struct PlateScanView: View {
    @ObservedObject var manager: FastingManager
    @Environment(\.dismiss) private var dismiss
    @State private var meal = EatingTime.current
    @State private var items: [PlateItem] = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var photo: CGImage?
    @State private var scanID: UUID?
    @State private var reading = false
    @State private var saving = false
    @State private var camera = false
    @State private var message = ""
    @State private var search: PlateSearchRequest?

    var body: some View {
        NavigationStack {
            ScrollView {
                JournalHeading(title: "Scan plate", subtitle: "Photograph your meal, then adjust what you ate.")
                VStack(alignment: .leading, spacing: 18) {
                    if let photo {
                        Image(decorative: photo, scale: 1).resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 205).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    if photo == nil || (!reading && items.isEmpty) {
                        HStack {
                            Button { Task { await openCamera() } } label: {
                                Label("Take photo", systemImage: "camera")
                            }.buttonStyle(JournalActionStyle())
                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Text("Choose photo").font(.headline).padding(.horizontal, 8)
                            }
                        }
                        Text("Your photo is analyzed on this device. Food names are used for nutrition lookups.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if reading { ProgressView("Identifying foods…") }
                    if !message.isEmpty {
                        Text(message).font(.subheadline)
                        if photo != nil, items.isEmpty, !reading {
                            Button("Try recognition again") { scanID = UUID() }
                        }
                    }
                    Picker("Meal", selection: $meal) {
                        ForEach(EatingTime.allCases, id: \.self) { Text($0.description.capitalized).tag($0) }
                    }.pickerStyle(.segmented)
                    ForEach($items) { $item in
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Text(item.food?.name ?? item.estimate.name).font(.headline)
                                Spacer()
                                Button { items.removeAll { $0.id == item.id } } label: {
                                    Image(systemName: "minus.circle").padding(5)
                                }.accessibilityLabel("Remove " + (item.food?.name ?? item.estimate.name))
                            }
                            if !item.estimate.name.isEmpty {
                                Text("Photo suggested " + item.estimate.name + (item.estimate.grams.map { " · about \($0) g" } ?? ""))
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            if let food = item.food {
                                Text([food.brand, "1 serving = " + food.portion.description(servings: 1)]
                                    .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.subheadline)
                            }
                            if let input = Binding($item.input) {
                                PlateAmountView(input: input)
                            }
                            HStack {
                                Button(item.food == nil ? "Choose food" : "Change food") {
                                    search = PlateSearchRequest(itemID: item.id, query: item.estimate.name)
                                }
                                if item.looking { ProgressView().accessibilityLabel("Looking up food") }
                                Spacer()
                                if let energy = item.energy { Text("\(energy.formatted(.number.precision(.fractionLength(0)))) kcal") }
                            }.font(.subheadline)
                            Divider()
                        }
                        .task(id: item.id) { await match(item.id, query: item.estimate.name) }
                    }
                    Button { search = PlateSearchRequest(itemID: nil, query: "") } label: {
                        Label("Add food", systemImage: "plus.circle")
                    }.disabled(reading)
                }.padding(20)
            }.journalPage()
            .safeAreaInset(edge: .bottom) {
                if !items.isEmpty {
                    let calories = items.compactMap(\.energy).reduce(0, +)
                    Button(saving ? "Logging…" : "Log \(meal.description.lowercased()) · \(calories.formatted(.number.precision(.fractionLength(0)))) kcal") {
                        guard !saving else { return }
                        saving = true
                        Task { await log() }
                    }
                    .buttonStyle(JournalActionStyle())
                    .disabled(saving || reading || items.contains { $0.energy == nil })
                    .padding(.horizontal, 20).padding(.vertical, 6).background(WarmInk.paper)
                }
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .disabled(saving)
        }
        .preferredColorScheme(.light).tint(WarmInk.action).interactiveDismissDisabled(saving)
        .fullScreenCover(isPresented: $camera) {
            CameraPhotoPicker { data in
                camera = false
                if let data { receive(data) }
            }.ignoresSafeArea()
        }
        .sheet(item: $search) { request in
            FoodSelectionView(query: request.query) { food in
                if let id = request.itemID {
                    if let index = items.firstIndex(where: { $0.id == id }) { items[index].use(food) }
                } else {
                    var item = PlateItem(estimate: PlateEstimate(name: "", grams: nil))
                    item.use(food)
                    items.append(item)
                }
                search = nil
            }
        }
        .task(id: pickerItem) {
            guard let pickerItem else { return }
            do {
                guard let data = try await pickerItem.loadTransferable(type: Data.self) else {
                    throw PlateReader.Failure("This photo could not be opened.")
                }
                try Task.checkCancellation()
                receive(data)
            } catch { if !Task.isCancelled { message = error.localizedDescription } }
        }
        .task(id: scanID) {
            guard scanID != nil, let photo else { return }
            reading = true
            message = ""
            do {
                let estimates = try await PlateReader.recognize(photo)
                try Task.checkCancellation()
                items.append(contentsOf: estimates.map { PlateItem(estimate: $0) })
                if estimates.isEmpty { message = "No foods identified. Try a closer photo or add a food below." }
            } catch { if !Task.isCancelled { message = error.localizedDescription } }
            if !Task.isCancelled { reading = false }
        }
    }

    private func receive(_ data: Data) {
        do {
            photo = try PlateReader.thumbnail(data)
            scanID = UUID()
        } catch { message = error.localizedDescription }
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            message = "A camera is unavailable here. Choose a photo instead."
            return
        }
        guard await AVCaptureDevice.requestAccess(for: .video) else {
            message = "Allow camera access for Dietic in Settings, or choose a photo."
            return
        }
        camera = true
    }

    @MainActor private func match(_ id: UUID, query: String) async {
        guard !query.isEmpty, items.first(where: { $0.id == id })?.looking == true else { return }
        let lookup = GroceryNameSearch()
        await lookup.search(query, online: false)
        if lookup.matches.isEmpty { await lookup.search(query) }
        let suggestion = lookup.matches.first
        var food: SavedFood?
        if !Task.isCancelled, let suggestion {
            food = try? await FoodDataCentral().product(for: suggestion.id)
        }
        guard !Task.isCancelled, let index = items.firstIndex(where: { $0.id == id }),
              items[index].looking else { return }
        if let food, food.nutrients[208] != nil { items[index].use(food) }
        else { items[index].looking = false }
    }

    @MainActor private func log() async {
        defer { saving = false }
        let date = manager.mealTimestamp
        let samples = items.compactMap { $0.sample(meal: meal, date: date) }
        guard !samples.isEmpty, samples.count == items.count else { return }
        do {
            try await manager.saveMeals(samples)
            dismiss()
        } catch { message = error.localizedDescription }
    }
}

private struct PlateAmountView: View {
    @Binding var input: PortionInput

    var body: some View {
        HStack {
            TextField("Amount", text: $input.text).keyboardType(.numbersAndPunctuation)
                .textFieldStyle(.roundedBorder).accessibilityLabel("Portion amount")
            Picker("Unit", selection: Binding(get: { input.unit }, set: { input.select($0) })) {
                ForEach(input.availableUnits, id: \.self) { Text(input.label(for: $0)).tag($0) }
            }.pickerStyle(.menu)
        }
    }
}

struct FoodSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var search = GroceryNameSearch()
    @ObservedObject private var favorites = FavoriteFoods.shared
    @State var query: String
    let select: (SavedFood) -> Void
    @State private var loading: FoodLookup?
    @State private var message = ""
    @State private var creatingFood = false

    private var usualFoods: [FavoriteFood] {
        (favorites.entries + favorites.personalFoods.filter { $0.pinned == false })
            .filter { $0.matches(search: query) }
    }

    private var recentGroceries: [SavedFood] {
        let usual = usualFoods
        return BarcodeFoods.shared.entries.values
            .sorted { $0.lastScan > $1.lastScan }
            .lazy.map(\.food)
            .filter { food in !usual.contains { $0.matches(food) } }
            .prefix(8).map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                if !message.isEmpty { Text(message) }
                if !usualFoods.isEmpty {
                    Section("My foods") {
                        ForEach(usualFoods) { item in
                            storedFood(item.food.using(item.portion))
                        }
                    }
                }
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let recent = recentGroceries
                    if !recent.isEmpty {
                        Section("Recent groceries") {
                            ForEach(recent.indices, id: \.self) { index in storedFood(recent[index]) }
                        }
                    }
                }
                ForEach(search.matches) { match in
                    Button { loading = match.id } label: {
                        VStack(alignment: .leading) {
                            Text(match.name).font(.headline)
                            Text([match.brand, match.subtitle].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }.disabled(loading != nil)
                }
                if loading != nil { ProgressView("Loading food…") }
                if !query.isEmpty, !search.status.isEmpty, usualFoods.isEmpty || !search.matches.isEmpty {
                    Text(search.status).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Choose food")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { creatingFood = true } label: { Label("Create food", systemImage: "plus") }
                        .disabled(loading != nil)
                }
            }
            .sheet(isPresented: $creatingFood) { PersonalFoodEditorView { food in query = food.name } }
        }.task(id: query) {
            loading = nil
            message = ""
            await search.search(query.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        .task(id: loading) {
            guard let loading else { return }
            do {
                let food = try await FoodDataCentral().product(for: loading)
                try Task.checkCancellation()
                guard food.nutrients[208] != nil else { throw FoodLookupError.noNutrition }
                select(food)
            } catch {
                if !Task.isCancelled { message = error.localizedDescription; self.loading = nil }
            }
        }
    }

    private func storedFood(_ food: SavedFood) -> some View {
        Button { select(food) } label: {
            VStack(alignment: .leading) {
                Text(food.name).font(.headline)
                Text([food.brand, food.portion.description(servings: 1)].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.disabled(loading != nil)
    }
}

struct CameraPhotoPicker: UIViewControllerRepresentable {
    let finish: (Data?) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(finish: finish) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let finish: (Data?) -> Void
        init(finish: @escaping (Data?) -> Void) { self.finish = finish }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { finish(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            finish((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.85))
        }
    }
}
