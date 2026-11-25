import SwiftUI
import UniformTypeIdentifiers

struct GroceryBackup: Codable {
    let format: String
    let version: Int
    let foods: [FavoriteFood]
    let barcodes: [String: BarcodeFoods.Entry]
    static let limit = 16 * 1024 * 1024

    enum Problem: LocalizedError {
        case invalid, tooLarge
        var errorDescription: String? {
            switch self {
            case .invalid: return "This file is missing valid Dietic grocery or portion data."
            case .tooLarge: return "This grocery backup exceeds the 16 MB limit."
            }
        }
    }

    @MainActor static func export(favorites: FavoriteFoods, groceries: BarcodeFoods) throws -> Data {
        try favorites.loadIfNeeded()
        let backup = Self(format: "dietic.groceries", version: 1, foods: favorites.backupRecords, barcodes: groceries.entries)
        try backup.validate()
        let data = try JSONEncoder().encode(backup)
        guard data.count <= limit else { throw Problem.tooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= limit else { throw Problem.tooLarge }
        let backup = try JSONDecoder().decode(Self.self, from: data)
        try backup.validate()
        return backup
    }

    @MainActor func restore(favorites: FavoriteFoods, groceries: BarcodeFoods) throws -> (foods: Int, barcodes: Int) {
        try validate()
        try favorites.loadIfNeeded()
        let savedFoods = try favorites.restoreMissing(foods)
        let savedBarcodes = try groceries.restoreMissing(barcodes)
        return (savedFoods, savedBarcodes)
    }

    private func validate() throws {
        func amount(_ n: Double) -> Bool { n.isFinite && n >= 0 && n <= 100_000_000 }
        func portion(_ portion: FoodPortion) -> Bool {
            amount(portion.quantity) && portion.quantity > 0 && (portion.grams.map(amount) ?? true)
            && !portion.unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        func food(_ food: SavedFood) -> Bool {
            !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && portion(food.portion)
            && !food.nutrients.isEmpty && food.nutrients.values.allSatisfy(amount)
            && (food.sourceURL.map { ["https", "http"].contains($0.scheme?.lowercased() ?? "") } ?? true)
        }
        guard format == "dietic.groceries", version == 1, Set(foods.map(\.id)).count == foods.count else { throw Problem.invalid }
        for item in foods {
            guard food(item.food), portion(item.portion), amount(item.quantity), item.quantity > 0,
                  !item.inGrams || (item.portion.grams ?? 0) > 0,
                  let servings = item.input.servings, amount(servings), servings > 0,
                  item.food.using(item.portion).nutrients.values.allSatisfy({ amount($0 * servings) }) else {
                throw Problem.invalid
            }
        }
        for (key, entry) in barcodes {
            guard key.utf8.count == 14, key.utf8.allSatisfy({ (48...57).contains($0) }),
                  food(entry.food), (0..<Int.max).contains(entry.scans),
                  entry.lastScan.timeIntervalSinceReferenceDate.isFinite else { throw Problem.invalid }
        }
    }

    static func read(_ url: URL) throws -> Self {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: limit + 1) ?? Data()
        return try decode(data)
    }
}

private struct GroceryBackupDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else { throw GroceryBackup.Problem.invalid }
        data = contents
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct GroceryBackupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var document: GroceryBackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var reading = false
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button { exportFile() } label: { Label("Export groceries", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("Restore from file", systemImage: "square.and.arrow.down") }
                } footer: {
                    Text("A backup includes your personal foods, favorite portions and saved barcode matches. Restoring adds missing foods and keeps your current matches.")
                }
                if reading { ProgressView("Reading backup…") }
                if !message.isEmpty { Text(message) }
            }
            .disabled(reading).scrollContentBackground(.hidden).background(WarmInk.paper)
            .navigationTitle("Back up groceries").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Dietic groceries") { result in
                if case .failure(let error) = result { report(error) }
                else { message = "Grocery backup exported." }
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    reading = true
                    message = ""
                    Task {
                        defer { reading = false }
                        do {
                            let backup = try await Task.detached { try GroceryBackup.read(url) }.value
                            let count = try backup.restore(favorites: .shared, groceries: .shared)
                            let foods = count.foods == 1 ? "saved food" : "saved foods"
                            let barcodes = count.barcodes == 1 ? "barcode match" : "barcode matches"
                            message = "Added \(count.foods) \(foods) and \(count.barcodes) \(barcodes)."
                        } catch { report(error) }
                    }
                } catch { report(error) }
            }
        }.tint(WarmInk.action).preferredColorScheme(.light)
    }

    private func exportFile() {
        do {
            document = GroceryBackupDocument(data: try GroceryBackup.export(favorites: .shared, groceries: .shared))
            exporting = true
        } catch { report(error) }
    }

    private func report(_ error: Error) {
        if (error as? CocoaError)?.code != .userCancelled { message = error.localizedDescription }
    }
}
