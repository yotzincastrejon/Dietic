import Foundation

enum MealLogError: LocalizedError {
    case healthPermission
    var errorDescription: String? {
        "Allow Dietic to write nutrition data in Health to log this meal."
    }
}

/// Nutrient amounts for one serving, indexed by USDA nutrient number.
struct SavedFood: Codable {
    let name: String
    let brand: String?
    let servingQuantity: Double
    let servingUnit: String
    let servingGrams: Double?
    let nutrients: [Int: Double]

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
            date: date, attrIDArray: nutrients.keys.sorted())
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
