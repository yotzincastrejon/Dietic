import Foundation

enum MealLogError: LocalizedError {
    case healthPermission
    var errorDescription: String? {
        "Allow Dietic to write nutrition data in Health to log this meal."
    }
}

/// Nutrient amounts for one serving, indexed by USDA nutrient number.
struct SavedFood: Codable, Equatable {
    let name: String
    let brand: String?
    let servingQuantity: Double
    let servingUnit: String
    let servingGrams: Double?
    let nutrients: [Int: Double]

    var householdServing: String? = nil
    var fdcID: Int? = nil

    var sourceName: String? = nil
    var sourceURL: URL? = nil

    var portion: FoodPortion {
        FoodPortion(quantity: servingQuantity, unit: servingUnit, grams: servingGrams, household: householdServing)
    }

    func using(_ newPortion: FoodPortion) -> SavedFood {
        guard newPortion != portion, let scale = newPortion.scale(relativeTo: portion) else { return self }
        return SavedFood(name: name, brand: brand, servingQuantity: newPortion.quantity, servingUnit: newPortion.unit,
                         servingGrams: newPortion.grams, nutrients: nutrients.mapValues { $0 * scale },
                         householdServing: newPortion.household, fdcID: fdcID, sourceName: sourceName, sourceURL: sourceURL)
    }

    static func readHistory(_ data: Data?) -> SavedFood? {
        guard let data else { return nil }
        let decoder = JSONDecoder()
        if let food = try? decoder.decode(Self.self, from: data) { return food }
        guard let history = try? decoder.decode(LegacyHistory.self, from: data),
              let old = history.foods.first, let name = old.foodName else { return nil }
        var values = [Int: Double]()
        for entry in old.fullNutrients { values[entry.attrID] = entry.value }
        if let value = old.calories { values[208] = value }
        if let value = old.sugars { values[269] = value }
        if let value = old.totalFat { values[204] = value }
        if let value = old.saturatedFat { values[606] = value }
        if let value = old.cholesterol { values[601] = value }
        if let value = old.sodium { values[307] = value }
        if let value = old.totalCarbohydrate { values[205] = value }
        if let value = old.dietaryFiber { values[291] = value }
        if let value = old.protein { values[203] = value }
        if let value = old.potassium { values[306] = value }
        return SavedFood(name: name, brand: old.brandName, servingQuantity: old.servingQuantity ?? 1,
                         servingUnit: old.servingUnit ?? "serving", servingGrams: old.servingWeightGrams,
                         nutrients: values)
    }

    func sample(multiplier: Double, quantity: Double, unit: ServingType,
                meal: EatingTime, date: Date) -> HKSampleWithDescription {
        func amount(_ id: Int) -> Double { (nutrients[id] ?? 0) * multiplier }
        return HKSampleWithDescription(
            foodName: name, brandName: brand ?? "", servingQuantity: servingQuantity,
            servingUnit: servingUnit, servingWeightGrams: servingGrams ?? 0,
            calories: amount(208), sugars: amount(269), totalFat: amount(204),
            saturatedFat: amount(606), cholesterol: amount(601), sodium: amount(307),
            totalCarbohydrate: amount(205), dietaryFiber: amount(291), protein: amount(203),
            potassium: amount(306), calcium: amount(301), iron: amount(303),
            monounsaturatedFat: amount(645), polyunsaturatedFat: amount(646), caffeine: amount(262),
            copper: amount(312), folate: amount(417), magnesium: amount(304),
            manganese: amount(315), niacin: amount(406), phosphorus: amount(305),
            riboflavin: amount(405), selenium: amount(317), thiamin: amount(404),
            vitaminA: amount(320), vitaminC: amount(401), vitaminB6: amount(415),
            vitaminB12: amount(418), vitaminD: amount(328), vitaminE: amount(323),
            vitaminK: amount(430), zinc: amount(309),
            mealPeriod: meal.description, numberOfServings: quantity,
            servingSelection: unit.description, uuid: UUID().uuidString,
            date: date, attrIDArray: nutrients.keys.sorted(), householdServing: householdServing)
    }
}

// Read-only compatibility with the first on-device meal history format.
private struct LegacyHistory: Decodable {
    let foods: [LegacyFood]
}
private struct LegacyFood: Decodable {
    let foodName: String?
    let brandName: String?
    let servingQuantity: Double?
    let servingUnit: String?
    let servingWeightGrams: Double?
    let calories: Double?
    let totalFat: Double?
    let saturatedFat: Double?
    let cholesterol: Double?
    let sodium: Double?
    let totalCarbohydrate: Double?
    let dietaryFiber: Double?
    let sugars: Double?
    let protein: Double?
    let potassium: Double?
    let fullNutrients: [LegacyNutrient]

    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case brandName = "brand_name"
        case servingQuantity = "serving_qty"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case calories = "nf_calories"
        case totalFat = "nf_total_fat"
        case saturatedFat = "nf_saturated_fat"
        case cholesterol = "nf_cholesterol"
        case sodium = "nf_sodium"
        case totalCarbohydrate = "nf_total_carbohydrate"
        case dietaryFiber = "nf_dietary_fiber"
        case sugars = "nf_sugars"
        case protein = "nf_protein"
        case potassium = "nf_potassium"
        case fullNutrients = "full_nutrients"
    }
}

private struct LegacyNutrient: Decodable {
    let attrID: Int
    let value: Double

    enum CodingKeys: String, CodingKey {
        case attrID = "attr_id"
        case value
    }
}

/// The database serving is the basis for nutrients. Household text only describes that same portion.
struct FoodPortion: Codable, Equatable {
    let quantity: Double
    let unit: String
    let grams: Double?
    let household: String?

    static func metricUnit(_ unit: String) -> String? {
        switch unit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
        case "g", "grm", "gm", "gram", "grams": return "g"
        case "ml", "mlt", "milliliter", "milliliters", "millilitre", "millilitres": return "mL"
        default: return nil
        }
    }

    var metricAmount: (value: Double, unit: String)? {
        if let grams, grams.isFinite, grams > 0 { return (grams, "g") }
        if let metric = Self.metricUnit(unit), quantity.isFinite, quantity > 0 { return (quantity, metric) }
        return nil
    }

    func scale(relativeTo base: FoodPortion) -> Double? {
        if self == base { return 1 }
        guard let new = metricAmount, let old = base.metricAmount, new.unit == old.unit else { return nil }
        let ratio = new.value / old.value
        return ratio.isFinite && ratio > 0 ? ratio : nil
    }

    static func package(count: Double, noun: String, amount: Double, unit: String) -> FoodPortion? {
        guard count.isFinite, count > 0, amount.isFinite, amount > 0, let metric = metricUnit(unit),
              let names = countUnits.first(where: { $0.1 == noun }) else { return nil }
        return FoodPortion(quantity: amount, unit: metric, grams: metric == "g" ? amount : nil,
                           household: "\(count) \(count == 1 ? names.0 : names.1)")
    }

    // The product name suggests a word for the picker, never a portion weight or count.
    static func suggestedNoun(for name: String) -> String {
        let words = name.lowercased().split { !$0.isLetter }
        return countUnits.first { words.contains(Substring($0.0)) || words.contains(Substring($0.1)) }?.1 ?? "pieces"
    }

    static var packageNouns: [String] { countUnits.map { $0.1 }.sorted() }

    func description(quantity entered: Double, measuredInGrams: Bool) -> String {
        guard measuredInGrams else { return description(servings: entered) }
        guard let grams, grams > 0 else { return "\(number(entered)) g" }
        return description(servings: entered / grams)
    }

    func description(servings: Double) -> String {
        let base = "\(number(quantity * servings)) \(Self.metricUnit(unit) ?? unit)"
        let metric = Self.metricUnit(unit) != nil
        let label = household?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, !label.isEmpty, !["n/a", "none", "not specified"].contains(label.lowercased()) {
            let words = label.split(whereSeparator: { $0.isWhitespace })
            if metric, words.count == 2, Double(words[0]) == quantity,
               Self.metricUnit(String(words[1])) == Self.metricUnit(unit) { return base }
            let householdAmount = scaledLabel(label, servings: servings)
            if householdAmount.caseInsensitiveCompare(base) == .orderedSame { return base }
            return "\(householdAmount) · \(base)"
        }
        if metric { return base }
        let portion = scaledLabel("\(quantity) \(unit)", servings: servings, fallback: base)
        if let grams, grams > 0 { return "\(portion) · \(number(grams * servings)) g" }
        return portion
    }

    private func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    struct ItemCount {
        let perServing: Double
        let singular: String
        let plural: String

        init?(_ label: String) {
            // A trailing metric equivalent is common on package labels, e.g. “2 patties (70 g)”.
            let countLabel = label.replacingOccurrences(of: #"(?i)\s*\(\s*\d+(?:\.\d+)?\s*(?:g|ml|oz)\s*\)\s*$"#,
                                                         with: "", options: .regularExpression)
            let words = countLabel.lowercased().split(whereSeparator: { $0.isWhitespace })
                .filter { !["cooked", "uncooked", "raw", "prepared", "small", "medium", "large", "jumbo"].contains($0) }
            guard let word = words.last,
                  let noun = FoodPortion.countUnits.first(where: { $0.0 == word || $0.1 == word }),
                  let count = PortionInput.parseAmount(words.dropLast().joined(separator: " ")) else { return nil }
            perServing = count
            (singular, plural) = noun
        }
    }

    var itemCount: ItemCount? {
        if let household, let count = ItemCount(household) { return count }
        if quantity == 1, unit.hasPrefix("serving ("), unit.hasSuffix(")") {
            return ItemCount(String(unit.dropFirst(9).dropLast()))
        }
        return ItemCount("\(quantity) \(unit)")
    }

    private func scaledLabel(_ label: String, servings: Double, fallback: String? = nil) -> String {
        if let count = ItemCount(label) {
            let total = count.perServing * servings
            return "\(number(total)) \(total == 1 ? count.singular : count.plural)"
        }
        if let fallback { return fallback }
        return servings == 1 ? label : "\(number(servings)) × (\(label))"
    }

    private static let countUnits = [
        ("can", "cans"), ("patty", "patties"), ("piece", "pieces"), ("slice", "slices"),
        ("bottle", "bottles"), ("bar", "bars"), ("egg", "eggs"), ("cookie", "cookies"),
        ("cracker", "crackers"), ("cup", "cups"), ("scoop", "scoops"), ("packet", "packets"),
        ("stick", "sticks"), ("link", "links"), ("nugget", "nuggets"), ("tortilla", "tortillas"),
        ("wing", "wings"), ("dumpling", "dumplings"), ("waffle", "waffles"), ("pancake", "pancakes"),
        ("chip", "chips"), ("meatball", "meatballs"), ("muffin", "muffins"), ("roll", "rolls"),
        ("bagel", "bagels"), ("bun", "buns"), ("sausage", "sausages"), ("fillet", "fillets"),
        ("strip", "strips"), ("tender", "tenders"), ("sandwich", "sandwiches"), ("biscuit", "biscuits"),
        ("bowl", "bowls"), ("carton", "cartons"), ("container", "containers"), ("pouch", "pouches"),
        ("tablet", "tablets"), ("tablespoon", "tablespoons"), ("teaspoon", "teaspoons")
    ]
}

/// Input units are a display choice. HealthKit continues to store servings or grams.
struct PortionInput {
    enum Unit: CaseIterable { case items, servings, grams, ounces, milliliters, fluidOunces, cups }

    private static let gramsPerOunce = 28.349523125
    private static let mlPerFluidOunce = 29.5735295625

    let portion: FoodPortion
    private(set) var unit: Unit
    var text: String

    init(portion: FoodPortion, savedQuantity: Double = 1, savedAsGrams: Bool = false) {
        self.portion = portion
        if savedAsGrams {
            unit = .grams
            text = Self.format(savedQuantity)
        } else if let count = portion.itemCount {
            unit = .items
            text = Self.format(savedQuantity * count.perServing)
        } else {
            unit = .servings
            text = Self.format(savedQuantity)
        }
    }

    var quantity: Double? {
        Self.parseAmount(text)
    }

    /// NumberFormatter also accepts numeric prefixes such as "2 eggs". Quantity fields need the whole input.
    static func decimal(_ raw: String, locale: Locale = .current) -> Double? {
        let raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let separator = locale.decimalSeparator ?? "."
        let normalized = raw.replacingOccurrences(of: separator, with: ".")
        guard !normalized.isEmpty, normalized.allSatisfy({ $0 == "." || $0.isWholeNumber }),
              let value = Double(normalized.map { $0.wholeNumberValue.map(String.init) ?? "." }.joined()),
              value.isFinite, value >= 0 else { return nil }
        return value
    }

    static func parseAmount(_ raw: String) -> Double? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for (symbol, replacement) in [("½","1/2"), ("¼","1/4"), ("¾","3/4"), ("⅓","1/3"), ("⅔","2/3")] {
            if text.hasSuffix(symbol) { text = String(text.dropLast()) + " " + replacement; break }
        }
        let parts = text.split(whereSeparator: \.isWhitespace)
        func number(_ part: Substring) -> Double? {
            Self.decimal(String(part))
        }
        guard let last = parts.last, parts.count <= 2 else { return nil }
        let pair = last.split(separator: "/", omittingEmptySubsequences: false)
        if pair.count == 1, parts.count == 1, let value = number(last), value > 0 { return value }
        guard pair.count == 2, let numerator = number(pair[0]), let denominator = number(pair[1]), denominator > 0 else { return nil }
        let whole = parts.count == 2 ? number(parts[0]) : 0
        guard let whole else { return nil }
        let value = whole + numerator / denominator
        return value > 0 && value.isFinite ? value : nil
    }

    var availableUnits: [Unit] {
        Unit.allCases.filter { (unitsPerServing($0) ?? 0) > 0 }
    }

    func label(for unit: Unit) -> String {
        switch unit {
        case .items: return portion.itemCount?.plural.capitalized ?? "Items"
        case .servings: return "Servings"
        case .grams: return "Grams"
        case .ounces: return "Ounces"
        case .milliliters: return "mL"
        case .fluidOunces: return "US fl oz"
        case .cups: return "US cups"
        }
    }

    private var servingVolumeML: Double? {
        guard portion.quantity.isFinite, portion.quantity > 0 else { return nil }
        if FoodPortion.metricUnit(portion.unit) == "mL" { return portion.quantity }
        let unit = portion.unit.lowercased().replacingOccurrences(of: ".", with: "")
        if ["fl oz", "fl_oz", "floz", "fluid ounce", "fluid ounces"].contains(unit) { return portion.quantity * Self.mlPerFluidOunce }
        if ["us cup", "us cups"].contains(unit) { return portion.quantity * 8 * Self.mlPerFluidOunce }
        if ["l", "liter", "liters", "litre", "litres"].contains(unit) { return portion.quantity * 1_000 }
        return nil
    }

    private func unitsPerServing(_ unit: Unit) -> Double? {
        switch unit {
        case .items: return portion.itemCount?.perServing
        case .grams: return portion.grams
        case .ounces: return portion.grams.map { $0 / Self.gramsPerOunce }
        case .milliliters: return servingVolumeML
        case .fluidOunces: return servingVolumeML.map { $0 / Self.mlPerFluidOunce }
        case .cups: return servingVolumeML.map { $0 / (8 * Self.mlPerFluidOunce) }
        case .servings: return 1
        }
    }

    var servings: Double? {
        guard let quantity, let factor = unitsPerServing(unit), factor > 0 else { return nil }
        let value = quantity / factor
        return value.isFinite && value > 0 ? value : nil
    }

    var savedQuantity: Double? { unit == .grams ? quantity : servings }
    var savedUnit: ServingType { unit == .grams ? .gram : .serving }

    mutating func select(_ newUnit: Unit) {
        guard newUnit != unit, let factor = unitsPerServing(newUnit), factor > 0 else { return }
        text = servings.map { Self.format($0 * factor) } ?? ""
        unit = newUnit
    }

    private static func format(_ number: Double) -> String {
        number.formatted(.number.grouping(.never).precision(.fractionLength(0...12)))
    }
}
