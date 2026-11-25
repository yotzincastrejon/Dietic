import XCTest
@testable import Dietic

final class DiaryRegressionTests: XCTestCase {
    func testCountedFoodsAndWeightKeepTheSameServing() throws {
        var input = PortionInput(portion: FoodPortion(quantity: 2, unit: "patties", grams: 90, household: nil))
        input.text = "3"
        XCTAssertEqual(input.servings, 1.5)
        input.select(.grams)
        XCTAssertEqual(input.savedQuantity, 135)
        input.select(.ounces)
        XCTAssertEqual(try XCTUnwrap(input.servings), 1.5, accuracy: 0.000001)
        XCTAssertFalse(input.availableUnits.contains(.cups))
    }

    func testLiquidsConvertWithoutInventingDensity() throws {
        var soda = PortionInput(portion: FoodPortion(quantity: 12, unit: "fl oz", grams: nil, household: "1 can"))
        soda.select(.cups)
        XCTAssertEqual(soda.quantity, 1.5)
        soda.text = "3/4"
        XCTAssertEqual(soda.servings, 0.5)
        soda.select(.milliliters)
        XCTAssertEqual(try XCTUnwrap(soda.quantity), 177.441177375, accuracy: 0.000001)
        XCTAssertFalse(soda.availableUnits.contains(.grams))
    }

    func testFractionsAndCompleteLocalizedNumbers() {
        XCTAssertEqual(PortionInput.parseAmount("2 3/4"), 2.75)
        XCTAssertEqual(PortionInput.parseAmount("1½"), 1.5)
        let household = FoodPortion.ItemCount("1 1/2 cups (90 g)")
        XCTAssertEqual(household?.perServing, 1.5)
        XCTAssertEqual(household?.singular, "cup")
        XCTAssertEqual(FoodPortion.ItemCount("½ bagel")?.perServing, 0.5)
        XCTAssertEqual(PortionInput.decimal("1,5", locale: Locale(identifier: "fr_FR")), 1.5)
        for text in ["2eggs", "0", "-1", "1/0", "2//3", "1/2/3", "2.3.4"] {
            XCTAssertNil(PortionInput.parseAmount(text), text)
        }
    }

    func testChangingTargetNeverChangesActualDeficit() throws {
        let energy = DailyEnergy(bmr: 1_600, active: 400, consumed: 1_750)
        var plan = NutritionPlan(goal: .deficit, level: .normal, focus: .balanced)
        let percentGoal = try XCTUnwrap(plan.calorieGoal(for: energy))
        XCTAssertEqual(percentGoal, Int((2_000 * plan.multiplier).rounded()))
        plan.fixedDeficit = 350
        XCTAssertEqual(plan.calorieGoal(for: energy), 1_650)
        XCTAssertEqual(plan.targetBalance(for: energy), 350)
        XCTAssertEqual(energy.deficit, 250)
        plan.goal = .maintaining
        XCTAssertEqual(plan.calorieGoal(for: energy), 2_000)
        XCTAssertNil(DailyCalorieBudget.intake(maintenance: nil, multiplier: 1, fixedDeficit: 350))
        XCTAssertNil(DailyCalorieBudget.intake(maintenance: 300, multiplier: 1, fixedDeficit: 350))
    }

    func testPartialMacroOverridesAndLegacyPlanDecode() throws {
        // Use the real raw values so changes to the displayed titles do not affect this fixture.
        let fixture = try JSONSerialization.data(withJSONObject: ["goal": DietGoal.maintaining.rawValue,
                                                                   "level": DietDeficitLevel.normal.rawValue,
                                                                   "focus": "balanced"])
        let plan = try JSONDecoder().decode(NutritionPlan.self, from: fixture)
        XCTAssertNil(plan.fixedDeficit)
        XCTAssertNil(plan.overrides)
        let targets = DailyMacroTargets(weightPounds: nil, calorieGoal: 2_000,
                                       overrides: MacroOverrides(protein: 150, carbs: nil, fat: 60))
        XCTAssertEqual(targets.carbs, 215)
        XCTAssertEqual(targets.protein, 150)
    }

    func testCSVQuotesFoodNamesAndPreservesMissingNutrients() {
        let food = SavedFood(name: "=Test, \"quoted\"", brand: nil, servingQuantity: 1, servingUnit: "bowl",
                             servingGrams: nil, nutrients: [208: 120, 203: 0])
        let sample = food.sample(multiplier: 1, quantity: 1, unit: .serving, meal: .lunch, date: .now)
        let csv = DiaryCSV(entries: [sample]).text
        XCTAssertTrue(csv.contains("\"'=Test, \"\"quoted\"\"\""))
        XCTAssertTrue(csv.contains("\"120.0\",\"0.0\",\"\",\"\",\"\",\"\",\"\""))
    }
}

final class SavedMealRegressionTests: XCTestCase {
    private var ingredients: [SharedMeal.Item] {
        let eggs = SavedFood(name: "Eggs", brand: nil, servingQuantity: 50, servingUnit: "g",
                             servingGrams: 50, nutrients: [208: 70], householdServing: "1 egg")
        let rice = SavedFood(name: "Rice", brand: nil, servingQuantity: 100, servingUnit: "g",
                             servingGrams: 100, nutrients: [208: 130])
        return [SharedMeal.Item(food: eggs, quantity: 2, inGrams: false),
                SharedMeal.Item(food: rice, quantity: 75, inGrams: true)]
    }

    func testFractionalServingsScaleEachIngredientInItsOwnUnit() throws {
        let recipe = MealTemplate(id: UUID(), name: "Rice bowl", meal: "Lunch", foods: ingredients, batchServings: 4)
        let portion = try XCTUnwrap(recipe.scaledInputs(for: 1.5))
        XCTAssertEqual(portion[0].quantity, 0.75)
        XCTAssertEqual(portion[0].unit, .items)
        XCTAssertEqual(portion[1].quantity, 28.125)
        XCTAssertEqual(portion[1].unit, .grams)
        XCTAssertEqual(recipe.foods[1].quantity, 75)
        XCTAssertNil(recipe.scaledInputs(for: 0))
        XCTAssertNil(MealTemplate.scaledInputs(ingredients, yield: .infinity, servingsEaten: 1))
    }

    @MainActor func testPersistAndEditRecipesWithoutOverwritingOtherMeals() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = MealTemplateLibrary(directory: directory)
        let second = MealTemplateLibrary(directory: directory)
        let saved = try first.save(name: "Lunch bowl", meal: "Lunch", foods: ingredients)
        try second.reload()
        try first.save(name: "New breakfast", meal: "Breakfast", foods: ingredients)
        try second.save(id: saved.id, name: "Lunch bowl", meal: "Lunch", foods: ingredients, batchServings: 2.5)
        try first.reload()
        let updated = try XCTUnwrap(first.templates.first { $0.id == saved.id })
        XCTAssertEqual(first.templates.count, 2)
        XCTAssertEqual(updated.batchServings, 2.5)
        XCTAssertThrowsError(try first.save(name: "Broken", meal: "Lunch", foods: ingredients, batchServings: 0))
        XCTAssertThrowsError(try second.save(name: "lunch bowl", meal: "Lunch", foods: ingredients))
        try second.delete(id: saved.id)
        try first.reload()
        XCTAssertEqual(first.templates.map(\.name), ["New breakfast"])
        let file = directory.appendingPathComponent("MealTemplates.json")
        let unreadable = Data("invalid JSON".utf8)
        try unreadable.write(to: file)
        XCTAssertThrowsError(try first.save(name: "Another lunch", meal: "Lunch", foods: ingredients))
        XCTAssertEqual(try Data(contentsOf: file), unreadable)
    }

    func testLegacyMealFilesAndNamedRecipeFilesRoundTrip() throws {
        let old = SharedMeal(version: 1, id: UUID(), meal: "Lunch", items: ingredients)
        let encoded = try old.encoded()
        let oldJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNil(oldJSON["templateName"])
        XCTAssertNil(oldJSON["batchServings"])
        let legacyTemplate: [String: Any] = ["id": old.id.uuidString, "name": "Saved lunch",
                                             "meal": old.meal, "foods": try XCTUnwrap(oldJSON["items"])]
        let legacyData = try JSONSerialization.data(withJSONObject: legacyTemplate)
        let regularMeal = try JSONDecoder().decode(MealTemplate.self, from: legacyData)
        XCTAssertNil(regularMeal.batchServings)
        XCTAssertEqual(regularMeal.foods.count, 2)
        let decoded = try JSONDecoder().decode(SharedMeal.self, from: encoded)
        XCTAssertNil(decoded.batchServings)
        try decoded.validate()
        var recipe = old
        recipe.templateName = "Rice bowl"
        recipe.batchServings = 4
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("dieticmeal")
        defer { try? FileManager.default.removeItem(at: file) }
        try recipe.encoded().write(to: file)
        let received = try SharedMeal.read(file)
        XCTAssertEqual(received.templateName, recipe.templateName)
        XCTAssertEqual(received.batchServings, 4)
        XCTAssertEqual(received.items[1].quantity, 75)
        recipe.batchServings = -1
        XCTAssertThrowsError(try recipe.encoded())
    }
}

extension DiaryRegressionTests {
    @MainActor
    func testGroceryBackupRestoresMissingFoodsAndPreservesExistingMatches() throws {
        let suite = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer {
            try? FileManager.default.removeItem(at: folder)
            defaults.removePersistentDomain(forName: suite)
        }
        let sourceFoods = FavoriteFoods(url: folder.appendingPathComponent("source.json"))
        let sourceBarcodes = BarcodeFoods(directory: folder.appendingPathComponent("source-scans"), defaults: defaults)
        let meals = FavoriteFoods(url: folder.appendingPathComponent("destination.json"))
        let scans = BarcodeFoods(directory: folder.appendingPathComponent("destination-scans"), defaults: defaults)
        let patties = SavedFood(name: "Patties", brand: nil, servingQuantity: 2, servingUnit: "patties",
                                servingGrams: 90, nutrients: [208: 200])
        let milk = SavedFood(name: "Milk", brand: nil, servingQuantity: 240, servingUnit: "mL",
                             servingGrams: nil, nutrients: [208: 120])
        let key = "00012345678905"
        var portion = PortionInput(portion: patties.portion)
        portion.text = "3"
        try sourceFoods.save(patties, input: portion)
        try sourceFoods.savePersonal(milk)
        try sourceFoods.remove(XCTUnwrap(sourceFoods.personalFoods.first).id)
        _ = try sourceBarcodes.rememberScan(patties, for: key)
        _ = try sourceBarcodes.recordScan(for: key)

        let data = try GroceryBackup.export(favorites: sourceFoods, groceries: sourceBarcodes)
        let backup = try GroceryBackup.decode(data)
        let added = try backup.restore(favorites: meals, groceries: scans)
        XCTAssertEqual(added.foods, 2)
        XCTAssertEqual(added.barcodes, 1)
        XCTAssertEqual(meals.entries.first?.input.servings, 1.5)
        XCTAssertEqual(meals.personalFoods.first?.pinned, false)
        XCTAssertEqual(scans.entries[key]?.scans, 2)
        XCTAssertEqual(scans.entries[key]?.lastScan, sourceBarcodes.entries[key]?.lastScan)

        try scans.save(milk, for: key)
        let repeated = try backup.restore(favorites: meals, groceries: scans)
        XCTAssertEqual(repeated.foods, 0)
        XCTAssertEqual(repeated.barcodes, 0)
        XCTAssertEqual(scans.food(for: key), milk)

        for invalidKey in ["../badfilepath", "０００１２３４５６７８９０５"] {
            let invalid = GroceryBackup(format: backup.format, version: backup.version, foods: backup.foods,
                                        barcodes: [invalidKey: try XCTUnwrap(sourceBarcodes.entries[key])])
            XCTAssertThrowsError(try invalid.restore(favorites: meals, groceries: scans))
        }
        let invalidFood = SavedFood(name: "Invalid", brand: nil, servingQuantity: 1, servingUnit: "serving",
                                    servingGrams: nil, nutrients: [208: .infinity])
        let invalidNutrition = GroceryBackup(format: backup.format, version: backup.version, foods: [],
                                             barcodes: [key: .init(food: invalidFood, scans: 1, lastScan: .now)])
        XCTAssertThrowsError(try invalidNutrition.restore(favorites: meals, groceries: scans))
        XCTAssertEqual(scans.entries.count, 1)
        XCTAssertEqual(scans.food(for: key), milk)
    }
}

extension DiaryRegressionTests {
    func testWidgetUsesTheDiaryTargetAfterPlanChanges() {
        var snapshot = DiaryWidgetData(day: .now, maintenance: 2_200, calories: 1_650, carbs: 200, protein: 100,
                                       fat: 50, proteinTarget: 105, fatTarget: 75, multiplier: 0.8)
        snapshot.apply(multiplier: 0.8, focus: .balanced, overrides: .init(protein: 125, carbs: nil, fat: 60), fixedDeficit: 350)
        XCTAssertEqual(snapshot.balance, 550)
        XCTAssertEqual(snapshot.calorieGoal, 1_850)
        XCTAssertEqual(snapshot.targetBalance, 350)
        XCTAssertEqual(snapshot.carbTarget, 202.5)
        snapshot.apply(multiplier: 0.8, focus: .balanced)
        XCTAssertEqual(snapshot.calorieGoal, 1_760)
        XCTAssertNil(snapshot.fixedDeficit)
    }
}
