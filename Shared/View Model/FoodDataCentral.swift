import Foundation

enum FoodLookup: Equatable {
    case food(Int)
    case barcode(String, compressed: Bool)
}

enum FoodLookupError: LocalizedError {
    case configuration, unauthorized, rateLimit, unavailable, noMatch, noNutrition

    var errorDescription: String? {
        switch self {
        case .configuration: return "Configure your personal Dietic access token and rebuild the app."
        case .unauthorized: return "The food lookup service rejected this build’s access token."
        case .rateLimit: return "USDA’s request limit was reached. Try again later."
        case .unavailable: return "FoodData Central is unavailable. Try again."
        case .noMatch: return "USDA has no matching food for this barcode."
        case .noNutrition: return "This USDA record has no usable calorie information."
        }
    }
}

struct FoodDataCentral {
    var accessToken = Bundle.main.object(forInfoDictionaryKey: "DieticAccessToken") as? String

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
        var subtitle: String { brandName ?? brandOwner ?? dataType }
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

    func product(for lookup: FoodLookup) async throws -> SavedFood {
        let id: Int
        switch lookup {
        case .food(let fdcID): id = fdcID
        case .barcode(let scanned, let compressed):
            let digits = Array(scanned)
            guard [8, 12, 13, 14].contains(digits.count),
                  digits.allSatisfy({ $0.isASCII && $0.isNumber }) else { throw FoodLookupError.noMatch }
            let code = compressed ? Self.expandUPCE(digits) : scanned
            // Vendors submit GTINs in different widths. Compare canonical GTINs before accepting a match.
            let canonical = String(repeating: "0", count: 14 - code.count) + code
            var tried = Set<String>()
            var match: Match?
            for width in [code.count, 14, 12, 13, 8] {
                let variant = String(canonical.suffix(width))
                guard canonical.dropLast(width).allSatisfy({ $0 == "0" }),
                      tried.insert(variant).inserted else { continue }
                let results = try await search(variant, brandedOnly: true)
                match = results.filter { food in
                    guard let gtin = food.gtinUpc, !gtin.isEmpty, gtin.count <= 14 else { return false }
                    return String(repeating: "0", count: 14 - gtin.count) + gtin == canonical
                }.max { $0.id < $1.id }
                if match != nil { break }
            }
            guard let match else { throw FoodLookupError.noMatch }
            id = match.id
        }
        let detail: Detail = try await fetch("food/\(id)", [])
        return try detail.food()
    }

    private static func expandUPCE(_ d: [Character]) -> String {
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
        var request = URLRequest(url: endpoint)
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
        let servingSize: Double?
        let servingSizeUnit: String?
        let foodPortions: [Portion]?
        let foodNutrients: [Nutrient]
        let labelNutrients: [String: LabelValue]?

        private var serving: (quantity: Double, unit: String, basis: Double, grams: Double?) {
            let unit = servingSizeUnit?.lowercased()
            if let size = servingSize, size > 0 {
                if ["ml", "mlt"].contains(unit) { return (size, "mL", size, nil) }
                if ["g", "grm"].contains(unit) { return (size, "g", size, size) }
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
            if servingSize == portion.basis, servingSizeUnit != nil {
                let labels = ["calories": 208, "protein": 203, "fat": 204, "carbohydrates": 205,
                              "fiber": 291, "sugars": 269, "sodium": 307, "saturatedFat": 606,
                              "cholesterol": 601, "potassium": 306, "calcium": 301, "iron": 303]
                for (name, id) in labels {
                    if let value = labelNutrients?[name]?.value { values[id] = value }
                }
            }
            guard values[208] != nil else { throw FoodLookupError.noNutrition }
            return SavedFood(name: description, brand: brandName ?? brandOwner,
                             servingQuantity: portion.quantity, servingUnit: portion.unit,
                             servingGrams: portion.grams, nutrients: values)
        }
    }
}
