import Foundation
import Combine

enum FoodLookup: Hashable {
    case savedGrocery(String)
    case openFoodFacts(String)
    case food(Int)
    case barcode(String, compressed: Bool)

    var digits: String? {
        if case .savedGrocery(let key) = self { return key }
        guard case .barcode(let scanned, let compressed) = self,
              [8, 12, 13, 14].contains(scanned.count),
              scanned.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        return compressed ? FoodDataCentral.expandUPCE(Array(scanned)) : scanned
    }

    var barcodeKey: String? { digits.map { String(repeating: "0", count: 14 - $0.count) + $0 } }
}

enum FoodLookupError: LocalizedError {
    case configuration, unauthorized, rateLimit, unavailable, noMatch, noNutrition, barcodeUnavailable

    var errorDescription: String? {
        switch self {
        case .configuration: return "Configure your personal Dietic access token and rebuild the app."
        case .unauthorized: return "The food lookup service rejected this build’s access token."
        case .rateLimit: return "USDA’s request limit was reached. Try again later."
        case .unavailable: return "FoodData Central is unavailable. Try again."
        case .barcodeUnavailable: return "Barcode lookup is temporarily unavailable. You can retry or save this package yourself."
        case .noMatch: return "No exact food match was found for this barcode."
        case .noNutrition: return "This food has no usable calorie information."
        }
    }
}

struct FoodDataCentral {
    var accessToken = Bundle.main.object(forInfoDictionaryKey: "DieticAccessToken") as? String

    private static func manufacturerPortion(_ gtin: String?) -> FoodPortion? {
        // Tyson provides a weight per cooked patty for each of these GTINs.
        // https://www.tysonfoodservice.com/products/jimmy-dean/breakfast/breakfast-sausage/10077900191388
        // https://www.tysonfoodservice.com/products/jimmy-dean/breakfast/breakfast-sausage/10077900193856
        let gramsPerPatty = ["10077900191388": 43.0, "10077900193856": 57.0]
        guard let gtin, let grams = gramsPerPatty[gtin] else { return nil }
        return .package(count: 1, noun: "patties", amount: grams, unit: "g")
    }

    struct Match: Decodable, Identifiable {
        struct Nutrient: Decodable {
            let nutrientNumber: String?
            let unitName: String?
            let value: Double?
        }

        let foodNutrients: [Nutrient]?
        let servingSizeUnit: String?
        let fdcId: Int
        let description: String
        let dataType: String
        let brandName: String?
        let brandOwner: String?
        let gtinUpc: String?
        var id: Int { fdcId }
        var subtitle: String {
            let source = brandName ?? brandOwner ?? dataType
            guard let portion = FoodDataCentral.manufacturerPortion(gtinUpc) else { return source }
            return "\(source) · \(portion.description(servings: 1))"
        }
        var energyDescription: String? {
            guard let energy = foodNutrients?.first(where: { $0.unitName?.lowercased() == "kcal" && $0.value != nil })?.value else { return nil }
            let unit = ["ml", "mlt"].contains(servingSizeUnit?.lowercased()) ? "mL" : "g"
            return "\(Int(energy.rounded())) kcal / 100 \(unit)"
        }
    }

    private struct Results: Decodable {
        let foods: [Match]
    }

    func search(_ query: String, brandedOnly: Bool = false) async throws -> [Match] {
        var parameters = [URLQueryItem(name: "query", value: query),
                          URLQueryItem(name: "pageSize", value: "40")]
        if brandedOnly { parameters.append(URLQueryItem(name: "dataType", value: "Branded")) }
        let result: Results = try await fetch("foods/search", parameters)
        return result.foods
    }

    func searchByName(_ term: String) async throws -> [Match] {
        let words = term.split(whereSeparator: { $0.isWhitespace })
        guard words.count > 1, words.allSatisfy({ $0.first?.isLetter == true || $0.first?.isNumber == true }) else {
            return try await search(term)
        }
        // USDA's default multiword search can discard the brand entirely.
        let matches = try await search(words.joined(separator: " AND "))
        if matches.isEmpty {
            try Task.checkCancellation()
            return try await search(term)
        }
        return matches
    }

    func product(for lookup: FoodLookup) async throws -> SavedFood {
        switch lookup {
        case .savedGrocery(let key):
            guard let food = await BarcodeFoods.shared.food(for: key) else { throw FoodLookupError.noMatch }
            return food
        case .openFoodFacts(let gtin):
            return try await OpenFoodFacts.product(gtin)
        case .food(let id):
            return try await usdaFood(id)
        case .barcode:
            guard let code = lookup.digits, let key = lookup.barcodeKey else { throw FoodLookupError.noMatch }
            if let saved = try await BarcodeFoods.shared.recordScan(for: key) { return saved }
            let food: SavedFood
            do {
                food = try await OpenFoodFacts.product(key)
            } catch {
                try Task.checkCancellation()
                let openFoodFactsError = error
                do {
                    food = try await usdaBarcode(code, key: key)
                } catch FoodLookupError.noMatch {
                    throw openFoodFactsError
                }
            }
            return try await BarcodeFoods.shared.rememberScan(food, for: key)
        }
    }

    private func usdaBarcode(_ code: String, key: String) async throws -> SavedFood {
        var tried = Set<String>()
        for width in [code.count, 14, 12, 13, 8] {
            let variant = String(key.suffix(width))
            guard key.dropLast(width).allSatisfy({ $0 == "0" }), tried.insert(variant).inserted else { continue }
            try Task.checkCancellation()
            let matches = try await search(variant, brandedOnly: true)
            let exact = matches.filter { match in
                guard let gtin = match.gtinUpc, !gtin.isEmpty, gtin.count <= 14 else { return false }
                return String(repeating: "0", count: 14 - gtin.count) + gtin == key
            }
            if let match = exact.max(by: { $0.id < $1.id }) { return try await usdaFood(match.id) }
        }
        throw FoodLookupError.noMatch
    }

    private func usdaFood(_ id: Int) async throws -> SavedFood {
        let detail: Detail = try await fetch("food/\(id)", [])
        var food = try detail.food()
        food.fdcID = id
        if let data = UserDefaults.standard.data(forKey: "packagePortion.\(id)"),
           let portion = try? JSONDecoder().decode(FoodPortion.self, from: data), portion.itemCount != nil {
            return food.using(portion)
        }
        return food
    }

    fileprivate static func expandUPCE(_ d: [Character]) -> String {
        guard d.count == 8 else { return String(d) }
        let head = String(d[0...2])
        switch d[6] {
        case "0", "1", "2": return head + String(d[6]) + "0000" + String(d[3...5]) + String(d[7])
        case "3": return String(d[0...3]) + "00000" + String(d[4...5]) + String(d[7])
        case "4": return String(d[0...4]) + "00000" + String(d[5]) + String(d[7])
        default: return String(d[0...5]) + "0000" + String(d[6...7])
        }
    }

    private func fetch<T: Decodable>(_ path: String, _ parameters: [URLQueryItem]) async throws -> T {
        guard let accessToken, !accessToken.isEmpty else { throw FoodLookupError.configuration }
        var url = URLComponents()
        url.scheme = "https"
        url.host = "dietic-food-lookup.yotzincastrejon.workers.dev"
        url.path = "/v1/" + path
        url.queryItems = parameters.isEmpty ? nil : parameters
        guard let endpoint = url.url else { throw FoodLookupError.unavailable }
        var request = URLRequest(url: endpoint, timeoutInterval: 12)
        request.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        request.setValue("Dietic/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200: return try JSONDecoder().decode(T.self, from: data)
        case 401, 403: throw FoodLookupError.unauthorized
        case 429: throw FoodLookupError.rateLimit
        default: throw FoodLookupError.unavailable
        }
    }

    private struct Detail: Decodable {
        struct Nutrient: Decodable {
            struct Definition: Decodable { let number: String? }
            let nutrient: Definition?
            let amount: Double?
        }
        struct Portion: Decodable {
            struct Measure: Decodable { let name: String? }
            let gramWeight: Double?
            let amount: Double?
            let measureUnit: Measure?
            let portionDescription: String?
            let modifier: String?
        }
        struct LabelValue: Decodable { let value: Double? }

        let description: String
        let brandName: String?
        let brandOwner: String?
        let gtinUpc: String?
        let householdServingFullText: String?
        let servingSize: Double?
        let servingSizeUnit: String?
        let foodPortions: [Portion]?
        let foodNutrients: [Nutrient]
        let labelNutrients: [String: LabelValue]?

        private var serving: (quantity: Double, unit: String, basis: Double, grams: Double?) {
            let unit = FoodPortion.metricUnit(servingSizeUnit ?? "")
            if let size = servingSize, size > 0 {
                if unit == "mL" { return (size, "mL", size, nil) }
                if unit == "g" { return (size, "g", size, size) }
            }
            if let p = foodPortions?.first(where: { ($0.gramWeight ?? 0) > 0 }),
               let weight = p.gramWeight {
                if let name = p.measureUnit?.name, !["undetermined", "quantity not specified", "undf"].contains(name.lowercased()),
                   let amount = p.amount, amount > 0 { return (amount, name, weight, weight) }
                if let name = p.portionDescription ?? p.modifier, !name.isEmpty {
                    return (1, "serving (\(name))", weight, weight)
                }
            }
            return (100, "g", 100, 100)
        }

        func food() throws -> SavedFood {
            let portion = serving
            var values = [Int: Double]()
            var specificEnergy: Double?
            var generalEnergy: Double?
            var totalSugars: Double?
            for entry in foodNutrients {
                guard let number = entry.nutrient?.number, let amount = entry.amount else { continue }
                let scaled = amount * portion.basis / 100
                switch number {
                case "958": specificEnergy = scaled
                case "957": generalEnergy = scaled
                case "269.3": totalSugars = scaled
                default: if let id = Int(number) { values[id] = scaled }
                }
            }
            values[208] = values[208] ?? specificEnergy ?? generalEnergy
            values[269] = values[269] ?? totalSugars
            // Label values already describe one labeled serving and preserve label rounding.
            let usesLabel = (servingSize ?? 0) > 0 && FoodPortion.metricUnit(servingSizeUnit ?? "") != nil
            if usesLabel {
                let labels = ["calories": 208, "protein": 203, "fat": 204, "carbohydrates": 205,
                              "fiber": 291, "sugars": 269, "sodium": 307, "saturatedFat": 606,
                              "cholesterol": 601, "potassium": 306, "calcium": 301, "iron": 303]
                for (name, id) in labels {
                    if let value = labelNutrients?[name]?.value { values[id] = value }
                }
            }
            guard values[208] != nil else { throw FoodLookupError.noNutrition }
            let food = SavedFood(name: description, brand: brandName ?? brandOwner,
                             servingQuantity: portion.quantity, servingUnit: portion.unit,
                             servingGrams: portion.grams, nutrients: values,
                             householdServing: usesLabel ? householdServingFullText : nil)
            guard food.portion.itemCount == nil else { return food }
            if let portion = FoodDataCentral.manufacturerPortion(gtinUpc) { return food.using(portion) }
            for option in foodPortions ?? [] {
                guard let weight = option.gramWeight, weight > 0 else { continue }
                let measure = option.measureUnit?.name ?? ""
                let labels = [option.portionDescription, option.modifier, option.amount.map { "\($0) \(measure)" }]
                for label in labels.compactMap({ $0 }) {
                    if let count = FoodPortion.ItemCount(label),
                       let portion = FoodPortion.package(count: count.perServing, noun: count.plural, amount: weight, unit: "g") {
                        return food.using(portion)
                    }
                }
            }
            return food
        }
    }
}

@MainActor
final class BarcodeFoods {
    struct Entry: Codable {
        let food: SavedFood
        var scans: Int
        var lastScan: Date
    }

    static let shared = BarcodeFoods()
    let changes = PassthroughSubject<Void, Never>()
    private(set) var entries = [String: Entry]()
    private let directory: URL
    private let defaults: UserDefaults
    private let oldPrefix = "barcodeFood.v1."

    init(directory: URL = URL.applicationSupportDirectory.appendingPathComponent("ScannedGroceries"),
         defaults: UserDefaults = .standard) {
        self.directory = directory
        self.defaults = defaults
        // Existing manually matched packages remain usable, including before their next scan.
        for (key, value) in defaults.dictionaryRepresentation() where key.hasPrefix(oldPrefix) {
            let gtin = String(key.dropFirst(oldPrefix.count))
            if let data = value as? Data, let food = try? JSONDecoder().decode(SavedFood.self, from: data) {
                entries[gtin] = Entry(food: food, scans: 0, lastScan: .distantPast)
            }
        }
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file), let entry = try? JSONDecoder().decode(Entry.self, from: data) {
                entries[file.deletingPathExtension().lastPathComponent] = entry
            }
        }
    }

    func food(for key: String) -> SavedFood? { entries[key]?.food }

    func recordScan(for key: String) throws -> SavedFood? {
        try Task.checkCancellation()
        guard var entry = entries[key] else { return nil }
        if entry.scans < Int.max { entry.scans += 1 }
        entry.lastScan = .now
        try store(entry, for: key)
        return entry.food
    }

    func rememberScan(_ food: SavedFood, for key: String) throws -> SavedFood {
        // A user correction can arrive while the remote lookup is in flight.
        if let existing = try recordScan(for: key) { return existing }
        try store(Entry(food: food, scans: 1, lastScan: .now), for: key)
        return food
    }

    func save(_ food: SavedFood, for key: String) throws {
        let existing = entries[key]
        try store(Entry(food: food, scans: existing?.scans ?? 1, lastScan: existing?.lastScan ?? .now), for: key)
    }

    private func store(_ entry: Entry, for key: String, announce: Bool = true) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(entry).write(to: directory.appendingPathComponent(key + ".json"), options: .atomic)
        defaults.removeObject(forKey: oldPrefix + key)
        entries[key] = entry
        if announce { changes.send() }
    }

    func forget(_ key: String) throws {
        let file = directory.appendingPathComponent(key + ".json")
        if FileManager.default.fileExists(atPath: file.path) { try FileManager.default.removeItem(at: file) }
        defaults.removeObject(forKey: oldPrefix + key)
        entries.removeValue(forKey: key)
        changes.send()
    }

    func restoreMissing(_ incoming: [String: Entry]) throws -> Int {
        var restored = 0
        defer { if restored > 0 { changes.send() } }
        for (key, entry) in incoming where entries[key] == nil {
            guard key.utf8.count == 14, key.utf8.allSatisfy({ (48...57).contains($0) }) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            try store(entry, for: key, announce: false)
            restored += 1
        }
        return restored
    }
}

enum OpenFoodFacts {
    private static let userAgent = "Dietic/1.0 (https://github.com/yotzincastrejon/Dietic)"

    static func search(_ term: String) async throws -> [GroceryMatch] {
        struct Response: Decodable {
            struct Hit: Decodable {
                let code: String?
                let product_name_en: String?
                let product_name: String?
                let brands: [String]?
                let quantity: String?
            }
            let hits: [Hit]
        }

        var url = URLComponents(string: "https://search.openfoodfacts.org/search")!
        url.queryItems = [
            URLQueryItem(name: "q", value: term.lowercased()),
            URLQueryItem(name: "langs", value: "en"),
            URLQueryItem(name: "page_size", value: "25"),
            URLQueryItem(name: "fields", value: "code,product_name_en,product_name,brands,quantity")
        ]
        var request = URLRequest(url: url.url!, timeoutInterval: 12)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        var seen = Set<String>()
        return try JSONDecoder().decode(Response.self, from: data).hits.compactMap { hit in
            let names = [hit.product_name_en, hit.product_name].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let name = names.first(where: { !$0.isEmpty }), let code = hit.code,
                  let key = FoodLookup.barcode(code, compressed: false).barcodeKey, seen.insert(key).inserted else { return nil }
            let brands = (hit.brands ?? []).map { $0.hasPrefix("xx:") ? String($0.dropFirst(3)) : $0 }.joined(separator: ", ")
            let subtitle = [brands, hit.quantity ?? ""].filter { !$0.isEmpty }.joined(separator: " · ")
            return GroceryMatch(id: .openFoodFacts(key), name: name, brand: brands, detail: subtitle, energy: nil)
        }
    }

    static func product(_ gtin: String) async throws -> SavedFood {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(gtin).json")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "fields", value: "code,product_name_en,product_name,brands,serving_size,serving_quantity,serving_quantity_unit,product_quantity_unit,nutrition_data_per,nutriments")]
        var request = URLRequest(url: components.url!, timeoutInterval: 12)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (bytes, response) = try await URLSession.shared.data(for: request)
        switch (response as? HTTPURLResponse)?.statusCode {
        case 200: return try decode(bytes, matching: gtin)
        case 404: throw FoodLookupError.noMatch
        default: throw FoodLookupError.barcodeUnavailable
        }
    }

    static func decode(_ bytes: Data, matching gtin: String) throws -> SavedFood {
        let json = try JSONSerialization.jsonObject(with: bytes) as? [String: Any]
        guard let product = json?["product"] as? [String: Any], let code = product["code"] as? String,
              FoodLookup.barcode(code, compressed: false).barcodeKey == gtin else { throw FoodLookupError.noMatch }
        let names = [product["product_name_en"], product["product_name"]].compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard let name = names.first(where: { !$0.isEmpty }), let nutrients = product["nutriments"] as? [String: Any] else { throw FoodLookupError.noNutrition }

        func number(_ raw: Any?) -> Double? {
            let value = (raw as? NSNumber)?.doubleValue ?? (raw as? String).flatMap(Double.init)
            guard let value, value.isFinite, value >= 0, value < 1_000_000_000 else { return nil }
            return value
        }
        func metric(_ raw: Any?) -> String? {
            guard let raw = raw as? String else { return nil }
            switch raw.lowercased() {
            case "l", "cl", "dl": return "mL"
            case "kg": return "g"
            default: return FoodPortion.metricUnit(raw)
            }
        }

        let label = (product["serving_size"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let size = number(product["serving_quantity"]).flatMap { $0 > 0 ? $0 : nil }
        // OFF serving_quantity is normalized to grams or milliliters.
        let servingMetric = FoodPortion.metricUnit(product["serving_quantity_unit"] as? String ?? "")
        let hasSize = size != nil && servingMetric != nil
        let hasServingEnergy = number(nutrients["energy-kcal_serving"]) != nil || number(nutrients["energy-kj_serving"]) != nil || number(nutrients["energy_serving"]) != nil
        let useServing = hasSize || (hasServingEnergy && label?.isEmpty == false)
        let referenceUnit = product["nutrition_data_per"] as? String == "100ml" ? "mL" : (metric(product["product_quantity_unit"]) ?? "g")
        let unit = useServing ? (hasSize ? servingMetric! : "serving") : referenceUnit
        let quantity = useServing ? (hasSize ? size! : 1) : 100
        func amount(_ nutrient: String) -> Double? {
            if useServing, let value = number(nutrients[nutrient + "_serving"]) { return value }
            guard !useServing || hasSize, let basis = number(nutrients[nutrient + "_100g"]) else { return nil }
            return basis * quantity / 100
        }
        guard let kcal = amount("energy-kcal") ?? (amount("energy-kj") ?? amount("energy")).map({ $0 / 4.184 }) else { throw FoodLookupError.noNutrition }
        // Allow ample margin above pure fat (9 kcal/g) for volume measures and label rounding.
        // Some crowdsourced records have misplaced decimals or use package calories as a density.
        guard unit == "serving" || kcal / quantity <= 12 else { throw FoodLookupError.noNutrition }
        var values = [208: kcal]
        for (field, id) in [("proteins",203), ("carbohydrates",205), ("fat",204), ("saturated-fat",606), ("sugars",269), ("fiber",291)] {
            values[id] = amount(field)
        }
        for (field, id) in [("sodium",307), ("cholesterol",601), ("calcium",301), ("iron",303), ("potassium",306)] {
            values[id] = amount(field).map { $0 * 1000 }
        }
        return SavedFood(name: name, brand: product["brands"] as? String, servingQuantity: quantity, servingUnit: unit,
                         servingGrams: unit == "g" ? quantity : nil, nutrients: values,
                         householdServing: useServing ? label : nil, sourceName: "Open Food Facts",
                         sourceURL: URL(string: "https://world.openfoodfacts.org/product/" + code))
    }
}

struct GroceryMatch: Identifiable {
    let id: FoodLookup
    let name: String
    let brand: String
    let detail: String
    let energy: String?
    var gtin: String? = nil

    var isSaved: Bool {
        if case .savedGrocery = id { return true }
        return false
    }

    var subtitle: String {
        let source: String
        switch id {
        case .savedGrocery: source = "Saved grocery"
        case .openFoodFacts: source = "Open Food Facts"
        default: source = "USDA"
        }
        return detail.isEmpty ? source : detail + " · " + source
    }
}

@MainActor
final class GroceryNameSearch: ObservableObject {
    private enum Source: String, CaseIterable { case usda = "USDA", openFoodFacts = "Open Food Facts" }
    private struct Batch {
        var matches: [GroceryMatch] = []
        var failed = false
    }

    @Published private var batches: [Source: Batch] = [:]

    @Published private(set) var matches = [GroceryMatch]()

    private var term = ""
    private var excludedBarcode: String?
    private var libraryChanges: AnyCancellable?

    init() {
        libraryChanges = BarcodeFoods.shared.changes.sink { [weak self] in
            guard let self, !self.term.isEmpty else { return }
            self.matches = self.rankedMatches(for: self.term)
        }
    }

    private func words(_ value: String) -> [String] {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
    }

    private func rankedMatches(for term: String) -> [GroceryMatch] {
        let query = words(term)
        guard !query.isEmpty else { return [] }
        let wanted = Set(query)
        // Only promote a saved item if its name and brand cover every typed word.
        let saved = BarcodeFoods.shared.entries.compactMap { key, entry -> (key: String, value: BarcodeFoods.Entry, exactWords: Int)? in
            guard key != excludedBarcode else { return nil }
            let tokens = words(entry.food.name + " " + (entry.food.brand ?? ""))
            guard wanted.allSatisfy({ word in tokens.contains { $0.hasPrefix(word) } }) else { return nil }
            return (key, entry, wanted.intersection(tokens).count)
        }.sorted { lhs, rhs in
            if lhs.exactWords != rhs.exactWords { return lhs.exactWords > rhs.exactWords }
            if lhs.value.scans != rhs.value.scans { return lhs.value.scans > rhs.value.scans }
            if lhs.value.lastScan != rhs.value.lastScan { return lhs.value.lastScan > rhs.value.lastScan }
            return lhs.key < rhs.key
        }
        let localKeys = Set(saved.map(\.key))
        let localIDs = Set(saved.compactMap { $0.value.food.fdcID })
        let local = saved.map { key, entry, _ in
            let food = entry.food
            let portion = food.portion.description(servings: 1)
            let detail = [food.brand, portion].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            return GroceryMatch(id: .savedGrocery(key), name: food.name, brand: food.brand ?? "", detail: detail,
                                energy: food.nutrients[208].map { "\(Int($0.rounded())) kcal" })
        }
        // Both providers use the same comparisons. Their own result positions break equally close matches.
        let candidates = Source.allCases.flatMap { (batches[$0]?.matches ?? []).enumerated().map { $0 } }
        let remote = candidates.filter { _, match in
            switch match.id {
            case .openFoodFacts(let key): return !localKeys.contains(key)
            case .food(let id): return !localIDs.contains(id) && !localKeys.contains(match.gtin ?? "")
            default: return true
            }
        }
        return local + remote.map { index, match in
            let name = words(match.name)
            let details = words(match.detail)
            let coverage = wanted.intersection(name + details).count
            let brand = words(match.brand)
            let exact = name == query || brand + name == query || name + brand == query
            // Brands often appear in both fields. Count those terms only once.
            let titleMatches = wanted.subtracting(brand).intersection(name).count
            let endsWithQueryWord = name.last.map(wanted.contains) ?? false
            let extra = Set(name).subtracting(wanted).count
            let rank = (-coverage, exact ? 0 : 1, endsWithQueryWord ? 0 : 1, -titleMatches, extra, index)
            return (match, rank)
        }.sorted { $0.1 < $1.1 }.map { $0.0 }
    }

    var status: String {
        if batches.isEmpty { return "Searching…" }
        var messages = [String]()
        for source in Source.allCases {
            if batches[source] == nil { messages.append("Searching " + source.rawValue + "…") }
            else if batches[source]?.failed == true { messages.append(source.rawValue + " is unavailable.") }
        }
        if messages.isEmpty && matches.isEmpty { return "No matching foods." }
        return messages.joined(separator: " ")
    }

    func search(_ term: String, excludingBarcode: String? = nil, online: Bool = true) async {
        guard !Task.isCancelled else { return }
        self.term = term
        excludedBarcode = excludingBarcode
        batches = [:]
        matches = rankedMatches(for: term)
        guard online, !term.isEmpty else { return }
        do { try await Task.sleep(nanoseconds: 600_000_000) } catch { return }
        async let usda: Void = load(.usda, term)
        async let off: Void = load(.openFoodFacts, term)
        _ = await (usda, off)
    }

    private func load(_ source: Source, _ term: String) async {
        do {
            let matches: [GroceryMatch]
            switch source {
            case .usda:
                matches = try await FoodDataCentral().searchByName(term).map {
                    GroceryMatch(id: .food($0.id), name: $0.description, brand: $0.brandName ?? $0.brandOwner ?? "",
                                 detail: $0.subtitle, energy: $0.energyDescription,
                                 gtin: $0.gtinUpc.flatMap { FoodLookup.barcode($0, compressed: false).barcodeKey })
                }
            case .openFoodFacts:
                matches = try await OpenFoodFacts.search(term)
            }
            try Task.checkCancellation()
            batches[source] = Batch(matches: matches)
            self.matches = rankedMatches(for: term)
        } catch {
            if !Task.isCancelled { batches[source] = Batch(failed: true) }
        }
    }
}
