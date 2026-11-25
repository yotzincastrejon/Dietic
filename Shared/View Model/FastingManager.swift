//
//  FastingManager.swift
//  Deficit Revised
//
//  Created by Yotzin Castrejon on 4/26/21.
//

import Foundation
import HealthKit
import Combine
import WidgetKit


struct DailyEnergy {
    var bmr: Double?
    var active: Double?
    var consumed: Double?
    var resting: Double?
    var activeReadFailed = false
    var recordedWeightPounds: Double?

    var activeForEstimate: Double? {
        activeReadFailed ? nil : (active ?? 0)
    }

    var recordedBurn: Double? {
        guard let active, let resting else { return nil }
        return active + resting
    }

    var estimatedMaintenance: Double? {
        guard let bmr, let activeForEstimate else { return nil }
        return bmr + activeForEstimate
    }

    var deficit: Double? {
        guard let estimatedMaintenance, let consumed else { return nil }
        return estimatedMaintenance - consumed
    }

    func targetDeficit(intakeMultiplier: Double) -> Double? {
        estimatedMaintenance.map { $0 - $0 * intakeMultiplier }
    }
}

class FastingManager: ObservableObject {
    
    
    
    //Store Time Specific Variables
    // - fast duration
    // - Progress
    // - State Text
    
    /// - Tag: Timer View Variables
    @Published var fastDuration: Int = 1
    @Published var progress: Double = 0
    @Published var fastingState: String = "Anabolic"
    
    //Store the following variables
    // - calories from workout
    // - weight
    // - height
    // - sex
    // - age
    
    /// - Tag: Caloric Calculations
    var weight: Double = 0
    var height: Double = 0
    var sex: String = ""
    var age: Int = 0
    private(set) var hasRecordedWeight = false
    var bodyFat: Double = 0
    
    /// - Tag: Macros Calculations
    @Published var carbPercentage: Double = 0
    @Published var proteinPercentage: Double = 0
    @Published var fatPercentage: Double = 0
    @Published var carbRemaining: Int = 0
    @Published var proteinRemaining: Int = 0
    @Published var fatRemaining: Int = 0
    
    ////// - Tag: Recent Sample Source
    var sampleSourceName: String = "Placeholder"
    var sampleSourceDate: Date = Date()
    
    /// - Tag: Declare HealthStore
    let healthStore = HKHealthStore()
    var query: HKStatisticsCollectionQuery?
    
    //Publish the following
    // - active calories
    // - passive calories
    // - total calories
    // - total fat loss
    // - elapsed seconds
    
    /// - Tag: Remaining Calories
    @Published var remainingCalories = 0.0
    @Published var percentageOfCaloriesRemaining = 0.0
    @Published var caloricConsumptionGoal = 2000.0
    
    /// - Tag: Caloric Deficit
    @Published var percentageOfCompletedGoal = 0.0
    
    
    /// - Tag: Publishers
    @Published private(set) var dailyEnergy = DailyEnergy()
    var activeCalories: Double { dailyEnergy.active ?? 0 }
    @Published var passiveCalories: Double = 0
    @Published var totalCalories: Double = 0
    @Published var fatLoss: Double = 0
    @Published var consumedCalories: Double = 0
    @Published var elapsedSeconds: Int = 0
    @Published var deficitGoal = 0
    @Published var carbohydrates: Double = 0
    @Published var protein: Double = 0
    @Published var fat: Double = 0
    @Published var poundsPerWeekYouWantToLose: Double = 0
    private var followsToday = true
    @Published var todaysDate = Date.now {
        didSet {
            if !Calendar.current.isDate(oldValue, inSameDayAs: todaysDate) {
                dailyEnergy = DailyEnergy()
                theSamples = []
                consumedCalories = 0
                carbohydrates = 0
                protein = 0
                fat = 0
            }
        }
    }
    @Published var bmr: Double = 0
    
    /// - Tag: Weight loss goal
    @Published var weightLossGoalInPounds = 50
    @Published var goalWeight = 115
    @Published var goalBodyFatPercentage: Double = 20
    @Published var futureDate = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 90,to: Date())!)
    @Published var percentageAccomplished = 0.00
    @Published var leftToBurn = 0.00
    @Published var dailyDeficitForGoal = 0.00
    @Published var currentDeficitForDay = 0.00
    @Published var simulatedCalories = 0
    @Published var simulatedCaloriesBool = false
    @Published var workoutPlan: WorkoutPlan = .weightLoss
    // MARK: - Timer Setup
    /// - Tag: TimerSetup
    //    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value:  0,to: Date())!)
    //    var end: Date = Date.now
    var cancellable: Cancellable?
    
    var mealTimestamp: Date { followsToday ? Date() : todaysDate }

    @MainActor func moveDay(by offset: Int) {
        let calendar = Calendar.current
        guard let next = calendar.date(byAdding: .day, value: offset, to: mealTimestamp),
              calendar.compare(next, to: Date(), toGranularity: .day) != .orderedDescending else { return }
        selectDay(next)
    }

    @MainActor func selectDay(_ next: Date) {
        followsToday = Calendar.current.isDateInToday(next)
        todaysDate = next
        scheduleDiaryUpdate()
    }

    @Published var isShowingDeficitByMass: Bool = true
    init() {
        isShowingDeficitByMass = UserDefaults.standard.bool(forKey: "IsShowingMass")
    }
    //Originally I had it pounds != nil just incase there is no value. We shall see if this works.
//    init() {
//        let pounds = UserDefaults.standard.double(forKey: "pounds")
//        if pounds != 0 {
//            poundsPerWeekYouWantToLose = pounds
//        }
//        let date = UserDefaults.standard.object(forKey: "Date") as? Date ?? Date()
//        if date != Date() {
//            futureDate = date
//        }
//
//        let goalWeightSaved = UserDefaults.standard.integer(forKey: "GoalWeight")
//        if goalWeightSaved != 0 {
//            goalWeight = goalWeightSaved
//        }
//
//        let goalBodyFat = UserDefaults.standard.double(forKey: "GoalBodyFatPercentage")
//        if goalBodyFat != 0 {
//            goalBodyFatPercentage = goalBodyFat
//        }
//
//        let bool = UserDefaults.standard.bool(forKey: "SimulatedBool")
//        if bool == true {
//            simulatedCaloriesBool = bool
//        }
//
//        let simulatedCal = UserDefaults.standard.integer(forKey: "SimulatedCalories")
//        if simulatedCal != 0 {
//            simulatedCalories = simulatedCal
//        }
//
//    }
    
    
    private static let quantityIDs: [HKQuantityTypeIdentifier] = [
        .activeEnergyBurned, .bodyMass, .height, .bodyFatPercentage,
        .dietaryCholesterol, .dietaryEnergyConsumed, .dietarySugar, .dietaryFatTotal,
        .dietaryFatSaturated, .dietarySodium, .dietaryCarbohydrates, .dietaryFiber,
        .dietaryProtein, .dietaryPotassium, .dietaryCalcium, .dietaryIron,
        .dietaryFatMonounsaturated, .dietaryFatPolyunsaturated, .dietaryCaffeine, .dietaryCopper,
        .dietaryFolate, .dietaryMagnesium, .dietaryManganese, .dietaryNiacin,
        .dietaryPhosphorus, .dietaryRiboflavin, .dietarySelenium, .dietaryThiamin,
        .dietaryVitaminA, .dietaryVitaminC, .dietaryVitaminB6, .dietaryVitaminB12,
        .dietaryVitaminD, .dietaryVitaminE, .dietaryVitaminK, .dietaryZinc,
    ]

    private var diaryObserver: HKObserverQuery?
    private var diaryActive = false
    @MainActor private var movingMeal = false
    private var updatePending = false
    private var updating = false

    deinit {
        if let diaryObserver { healthStore.stop(diaryObserver) }
    }

    @MainActor func setDiaryActive(_ active: Bool) {
        diaryActive = active
        if active { calendarChanged() }
    }

    @MainActor func calendarChanged() {
        if followsToday { todaysDate = Date() }
        scheduleDiaryUpdate()
    }

    @MainActor func scheduleDiaryUpdate() {
        guard diaryActive, HKHealthStore.isHealthDataAvailable() else { return }
        updatePending = true
        guard !updating else { return }
        updating = true
        Task {
            defer { updating = false }
            do {
                if diaryObserver == nil {
                    let quantities = Set(Self.quantityIDs.map { HKQuantityType($0) as HKSampleType })
                    var readTypes = Set<HKObjectType>(quantities)
                    readTypes.insert(HKQuantityType(.basalEnergyBurned))
                    readTypes.insert(HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!)
                    readTypes.insert(HKObjectType.characteristicType(forIdentifier: .biologicalSex)!)
                    let initialWrites = quantities.subtracting([HKQuantityType(.bodyMass)])
                    try await healthStore.requestAuthorization(toShare: initialWrites, read: readTypes)
                    observeDiaryChanges()
                }
                while diaryActive && updatePending {
                    updatePending = false
                    do { try await loadSelectedDay() }
                    catch { print("Diary update failed: \(error.localizedDescription)") }
                }
            } catch {
                print("Health access failed: \(error.localizedDescription)")
            }
        }
    }

    @MainActor private func observeDiaryChanges() {
        let ids: [HKQuantityTypeIdentifier] = [.dietaryEnergyConsumed, .dietaryCarbohydrates, .dietaryProtein,
                                               .dietaryFatTotal, .activeEnergyBurned, .basalEnergyBurned, .bodyMass, .height, .bodyFatPercentage]
        let descriptors = ids.map { HKQueryDescriptor(sampleType: HKQuantityType($0), predicate: nil) }
        let observer = HKObserverQuery(queryDescriptors: descriptors) { [weak self] _, _, complete, error in
            Task { @MainActor in
                defer { complete() }
                guard error == nil else { return }
                self?.scheduleDiaryUpdate()
            }
        }
        diaryObserver = observer
        healthStore.execute(observer)
    }

    func saveThing() {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { fatalError("It's not available anymore") }
        let value = 20.0
        let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: value)
        let date = Date.now
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date)
        healthStore.save(sample) { (success, error) in
            if let error = error {
                print("Error Saving Sample \(error.localizedDescription)")
            } else {
                print("Success in saving sample")
            }
        }
    }
    
    private func determineCaloricStanding(recordedActive: Double?, recordedResting: Double?, activeReadFailed: Bool) {
        bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        let hasProfile = hasRecordedWeight && weight > 0 && height > 0 && age > 0 && ["Male", "Female"].contains(sex)
        dailyEnergy = DailyEnergy(bmr: hasProfile && bmr > 0 ? bmr : nil, active: recordedActive, consumed: consumedCalories, resting: recordedResting, activeReadFailed: activeReadFailed,
                                  recordedWeightPounds: hasRecordedWeight ? weight : nil)
        let eatenCalories = consumedCalories
        let burnedCalories = activeCalories
        leftToBurn = eatenCalories - bmr - burnedCalories
        if leftToBurn < 0 {
            percentageAccomplished = 1
        } else {
            percentageAccomplished = (bmr + burnedCalories) / eatenCalories
        }
        //left to burn == the deficit/surplus (the result)
        //percentage accomplished.
        
    }
    
    func caloriesNeededToReachGoalWeight() {
        if !simulatedCaloriesBool {
            simulatedCalories = 0
        }
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        var eatencalories = consumedCalories
        let burnedCalories = activeCalories
        let bodyFatinPounds = bodyFat * weight
        let goalBodyFatInPounds = Double(goalWeight) * (goalBodyFatPercentage / 100)
        let weightToLoseInCalories = (bodyFatinPounds - goalBodyFatInPounds)*3500
        let differenceInDays = Calendar.current.dateComponents([.day], from: Date(), to: futureDate)
        let perdayCaloriesNeededToLose = weightToLoseInCalories / Double(differenceInDays.value(for: .day)!)
        let finalAmountOfNeededToBurn = perdayCaloriesNeededToLose - bmr
        //        print("Bmr: \(bmr)")
        //        print("perdayCaloriesNeededToLose: \(perdayCaloriesNeededToLose)")
        //        print("finalAmountNeededToBurn: \(finalAmountOfNeededToBurn)")
        //Here we are checking if simulated calories exceed actual consumed calories. We are showing what a simulated full meal would look like and how much you'd have to burn.
        if simulatedCaloriesBool && eatencalories < Double(simulatedCalories){
            eatencalories = 0
        }
        
        if eatencalories > Double(simulatedCalories) {
            simulatedCaloriesBool = false
            simulatedCalories = 0
            saveSimulatedCalories()
            saveSimulatedBool()
        }
        
        
        var afterMealsAndBurned = finalAmountOfNeededToBurn + eatencalories + Double(simulatedCalories)
        if afterMealsAndBurned == 0 {
            afterMealsAndBurned = 1
        }
        let finalPercentage = Double(burnedCalories / afterMealsAndBurned)
        //        print("finalAmountNeededToBurn: \(finalAmountOfNeededToBurn)")
        //        print("Burned Calories: \(burnedCalories)")
        //        print("After Meals and Burned: \(afterMealsAndBurned)")
        //        print("Final Percentage: \(finalPercentage)")
        if finalPercentage < 0 || finalPercentage >= 1{
            percentageAccomplished = 1
        } else {
            percentageAccomplished = Double(burnedCalories / afterMealsAndBurned)
            //            print("percentage Accomplished: \(percentageAccomplished)")
        }
        leftToBurn = Double(afterMealsAndBurned - burnedCalories)
        dailyDeficitForGoal = Double(perdayCaloriesNeededToLose)
        currentDeficitForDay = Double(eatencalories - bmr - burnedCalories)
        //        print("weight to lose: \(weightToLoseInCalories)")
        //        print("differenceInDays: \(differenceInDays)")
        //        print("perdayCalories Loss Goal: \(perdayCaloriesNeededToLose)")
        //        print("After accounting for BMR: \(finalAmountOfNeededToBurn)")
        //        print("Now Accounting for eaten calories: \(afterMealsAndBurned)")
        //        print("Left to Burn: \(afterMealsAndBurned - burnedCalories)")
        //        print("PercentageAccomplished: \(finalPercentage)")
    }
    
    func saveSimulatedCalories() {
        UserDefaults.standard.set(simulatedCalories, forKey: "SimulatedCalories")
    }
    
    func saveSimulatedBool() {
        UserDefaults.standard.set(simulatedCaloriesBool, forKey: "SimulatedBool")
    }
    
    func saveNewFutureDate() {
        UserDefaults.standard.set(futureDate, forKey: "Date")
    }
    
    func saveGoalWeight() {
        UserDefaults.standard.set(goalWeight, forKey: "GoalWeight")
    }
    
    func saveGoalBodyFat() {
        UserDefaults.standard.set(goalBodyFatPercentage, forKey: "GoalBodyFatPercentage")
    }
    
    func saveIsShowingDeficitByMass() {
        UserDefaults.standard.set(isShowingDeficitByMass, forKey: "IsShowingMass")
    }
    
    // MARK: - Health Kit Queries
    
    //Reusable query for getting the most recent sample. It takes a sample type of whatever you want to query and returns a recent sample.
    private static func isEmptyRead(_ error: Error) -> Bool {
        guard let healthError = error as? HKError else { return false }
        return [.errorNoData, .errorAuthorizationDenied, .errorAuthorizationNotDetermined].contains(healthError.code)
    }

    private func latestSample(_ id: HKQuantityTypeIdentifier, before end: Date) async throws -> HKQuantitySample? {
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: end, options: .strictEndDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: HKQuantityType(id), predicate: predicate, limit: 1,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error, !Self.isEmptyRead(error) { continuation.resume(throwing: error) }
                else { continuation.resume(returning: samples?.first as? HKQuantitySample) }
            }
            healthStore.execute(query)
        }
    }

    private func dailySum(_ id: HKQuantityTypeIdentifier, unit: HKUnit, predicate: NSPredicate) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: HKQuantityType(id), quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, error in
                if let error, !Self.isEmptyRead(error) {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
                }
            }
            healthStore.execute(query)
        }
    }

    // A calendar-day bucket lets HealthKit apportion energy samples that span midnight.
    private func recordedEnergy(_ id: HKQuantityTypeIdentifier, during day: DateInterval) async throws -> Double? {
        let end = min(day.end, Date())
        guard day.start < end else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: day.start, end: end)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(quantityType: HKQuantityType(id), quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum, anchorDate: day.start,
                                                    intervalComponents: DateComponents(day: 1))
            query.initialResultsHandler = { _, collection, error in
                if let error, (error as? HKError)?.code != .errorNoData {
                    continuation.resume(throwing: error)
                    return
                }
                let quantity = collection?.statistics(for: day.start)?.sumQuantity()
                continuation.resume(returning: quantity?.doubleValue(for: .kilocalorie()))
            }
            healthStore.execute(query)
        }
    }

    @MainActor private func loadSelectedDay() async throws {
        if !movingMeal {
            movingMeal = true
            do { _ = try await finishPendingMealMove() }
            catch { print("Meal move cleanup pending: \(error.localizedDescription)") }
            movingMeal = false
        }
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .day, for: todaysDate) else { return }
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end, options: .strictStartDate)
        async let meals = getCorrelationQuery(for: predicate)
        async let eaten = dailySum(.dietaryEnergyConsumed, unit: .kilocalorie(), predicate: predicate)
        async let active = recordedEnergy(.activeEnergyBurned, during: interval)
        async let resting = recordedEnergy(.basalEnergyBurned, during: interval)
        async let carbs = dailySum(.dietaryCarbohydrates, unit: .gram(), predicate: predicate)
        async let proteins = dailySum(.dietaryProtein, unit: .gram(), predicate: predicate)
        async let fats = dailySum(.dietaryFatTotal, unit: .gram(), predicate: predicate)
        async let weightSample = latestSample(.bodyMass, before: interval.end)
        async let heightSample = latestSample(.height, before: interval.end)
        async let fatSample = latestSample(.bodyFatPercentage, before: interval.end)

        let recordedActive: Double?
        let activeReadFailed: Bool
        do {
            recordedActive = try await active
            activeReadFailed = false
        } catch {
            recordedActive = nil
            activeReadFailed = true
        }
        let recordedResting = try? await resting
        let totals = try await (eaten, carbs, proteins, fats)
        let measurements = try await (weightSample, heightSample, fatSample)
        let correlations = try await meals
        guard diaryActive, interval == Calendar.current.dateInterval(of: .day, for: todaysDate) else { return }

        (consumedCalories, carbohydrates, protein, fat) = totals
        hasRecordedWeight = measurements.0 != nil
        weight = measurements.0?.quantity.doubleValue(for: .pound()) ?? 120
        height = measurements.1?.quantity.doubleValue(for: .inch()) ?? 0
        bodyFat = measurements.2?.quantity.doubleValue(for: .percent()) ?? 0
        sampleSourceName = measurements.0?.sourceRevision.source.name ?? "You have not entered a weight prior to this date."
        sampleSourceDate = measurements.0?.startDate ?? todaysDate
        let birth = try? healthStore.dateOfBirthComponents()
        age = birth.flatMap { calendar.date(from: $0) }
            .flatMap { calendar.dateComponents([.year], from: $0, to: interval.start).year } ?? 0
        sex = (try? healthStore.biologicalSex().biologicalSex.stringRepresentation) ?? ""
        determineCaloricStanding(recordedActive: recordedActive, recordedResting: recordedResting, activeReadFailed: activeReadFailed)
        let targets = nutritionPlan.targets(for: dailyEnergy)
        (proteinPercentage, proteinRemaining) = macroProgress(target: targets.protein, consumed: protein)
        (fatPercentage, fatRemaining) = macroProgress(target: targets.fat, consumed: fat)
        (carbPercentage, carbRemaining) = macroProgress(target: targets.carbs, consumed: carbohydrates)
        theSamples = mealSamples(from: correlations)
        if calendar.isDateInToday(interval.start) {
            let data = DiaryWidgetData(day: interval.start, maintenance: dailyEnergy.estimatedMaintenance,
                                       calories: consumedCalories, carbs: carbohydrates, protein: protein, fat: fat,
                                       proteinTarget: targets.protein, fatTarget: targets.fat,
                                       multiplier: nutritionPlan.multiplier, focus: nutritionPlan.focus,
                                       weightPounds: dailyEnergy.recordedWeightPounds, overrides: nutritionPlan.overrides,
                                       fixedDeficit: nutritionPlan.selectedFixedDeficit)
            saveWidgetData(data)
        }

    }

    private var nutritionPlan = NutritionPlan.legacy()

    @MainActor func applyPlan(_ plan: NutritionPlan) {
        nutritionPlan = plan
        if var data = DiaryWidgetRecord.today()?.data,
           data.multiplier != plan.multiplier || (data.focus ?? .balanced) != plan.focus || data.overrides != plan.overrides || data.fixedDeficit != plan.selectedFixedDeficit {
            data.apply(multiplier: plan.multiplier, focus: plan.focus, overrides: plan.overrides, fixedDeficit: plan.selectedFixedDeficit)
            saveWidgetData(data)
        }
        let targets = plan.targets(for: dailyEnergy)
        (proteinPercentage, proteinRemaining) = macroProgress(target: targets.protein, consumed: protein)
        (fatPercentage, fatRemaining) = macroProgress(target: targets.fat, consumed: fat)
        (carbPercentage, carbRemaining) = macroProgress(target: targets.carbs, consumed: carbohydrates)
    }

    private func saveWidgetData(_ data: DiaryWidgetData) {
        do {
            if try DiaryWidgetRecord.save(data) {
                WidgetCenter.shared.reloadTimelines(ofKind: DiaryWidgetRecord.kind)
            }
        } catch {
            print("Could not update the diary widget: \(error.localizedDescription)")
        }
    }

    private func macroProgress(target: Double?, consumed: Double) -> (percentage: Double, remaining: Int) {
        guard let target, target > 0 else { return (0, 0) }
        return (consumed / target, Int(target - consumed))
    }
    
    // MARK: - Eaten Foods Entry
    //Create an empty array to store food samples
    @Published var theSamples = [HKSampleWithDescription]()
    
    
    
    private func foodCorrelation(for sample: HKSampleWithDescription, importID: UUID? = nil) throws -> HKCorrelation {
        
        let foodType: HKCorrelationType = HKCorrelationType.correlationType(forIdentifier: .food)!
        var foodCorrelationMetadata: [String: Any] = [HKMetadataKeyFoodType: sample.uuid, "Food Name": sample.foodName, "Brand Name": sample.brandName, "Serving Quantity": sample.servingQuantity, "Serving Unit": sample.servingUnit, "Serving Weight Grams":sample.servingWeightGrams, "Meal Period": sample.mealPeriod, "Number Of Servings": sample.numberOfServings, "Serving Selection": sample.servingSelection]
        if let importID { foodCorrelationMetadata["Dietic Meal Import"] = importID.uuidString }
        if let household = sample.householdServing {
            foodCorrelationMetadata["Household Serving"] = household
        }
        var fromNutrientArray = Set<HKSample>()
        let attrIDArray:[Int: HKSample] = [
            203:HKSampleReturn(type: .dietaryProtein, value: sample.protein, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            204:HKSampleReturn(type: .dietaryFatTotal, value: sample.totalFat, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            205:HKSampleReturn(type: .dietaryCarbohydrates, value: sample.totalCarbohydrate, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            208:HKSampleReturn(type: .dietaryEnergyConsumed, value: sample.calories, quantity: .kilocalorie(), metadata: foodCorrelationMetadata, date: sample.date),
            262:HKSampleReturn(type: .dietaryCaffeine, value: sample.caffeine, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            269:HKSampleReturn(type: .dietarySugar, value: sample.sugars, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            291:HKSampleReturn(type: .dietaryFiber, value: sample.dietaryFiber, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            301:HKSampleReturn(type: .dietaryCalcium, value: sample.calcium, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            303:HKSampleReturn(type: .dietaryIron, value: sample.iron, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            304:HKSampleReturn(type: .dietaryMagnesium, value: sample.magnesium, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            305:HKSampleReturn(type: .dietaryPhosphorus, value: sample.phosphorus, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            306:HKSampleReturn(type: .dietaryPotassium, value: sample.potassium, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            307:HKSampleReturn(type: .dietarySodium, value: sample.sodium, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            309:HKSampleReturn(type: .dietaryZinc, value: sample.zinc, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            312:HKSampleReturn(type: .dietaryCopper, value: sample.copper, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            315:HKSampleReturn(type: .dietaryManganese, value: sample.manganese, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            317:HKSampleReturn(type: .dietarySelenium, value: sample.selenium, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            320:HKSampleReturn(type: .dietaryVitaminA, value: sample.vitaminA, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            323:HKSampleReturn(type: .dietaryVitaminE, value: sample.vitaminE, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            328:HKSampleReturn(type: .dietaryVitaminD, value: sample.vitaminD, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            401:HKSampleReturn(type: .dietaryVitaminC, value: sample.vitaminC, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            404:HKSampleReturn(type: .dietaryThiamin, value: sample.thiamin, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            405:HKSampleReturn(type: .dietaryRiboflavin, value: sample.riboflavin, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            406:HKSampleReturn(type: .dietaryNiacin, value: sample.niacin, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            415:HKSampleReturn(type: .dietaryVitaminB6, value: sample.vitaminB6, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            417:HKSampleReturn(type: .dietaryFolate, value: sample.folate, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            418:HKSampleReturn(type: .dietaryVitaminB12, value: sample.vitaminB12, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            430:HKSampleReturn(type: .dietaryVitaminK, value: sample.vitaminK, quantity: .gramUnit(with: .micro), metadata: foodCorrelationMetadata, date: sample.date),
            601:HKSampleReturn(type: .dietaryCholesterol, value: sample.cholesterol, quantity: .gramUnit(with: .milli), metadata: foodCorrelationMetadata, date: sample.date),
            606:HKSampleReturn(type: .dietaryFatSaturated, value: sample.saturatedFat, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            645:HKSampleReturn(type: .dietaryFatMonounsaturated, value: sample.monounsaturatedFat, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date),
            646:HKSampleReturn(type: .dietaryFatPolyunsaturated, value: sample.polyunsaturatedFat, quantity: .gram(), metadata: foodCorrelationMetadata, date: sample.date)
        ]
        
        
        for id in sample.attrIDArray {
            guard let nutrient = attrIDArray[id],
                  healthStore.authorizationStatus(for: nutrient.sampleType) == .sharingAuthorized else { continue }
            fromNutrientArray.insert(nutrient)
        }

        guard !fromNutrientArray.isEmpty else { throw MealLogError.healthPermission }
        return HKCorrelation(type: foodType, start: sample.date, end: sample.date,
                             objects: fromNutrientArray, metadata: foodCorrelationMetadata)
    }

    func saveMeal(_ sample: HKSampleWithDescription) async throws {
        try await saveMeals([sample])
    }

    func saveMeals(_ samples: [HKSampleWithDescription]) async throws {
        let correlations = try samples.map { try foodCorrelation(for: $0) }
        try await healthStore.save(correlations)
        await scheduleDiaryUpdate()
    }

    @MainActor private var importsInProgress = Set<UUID>()

    func hasImportedMeal(_ id: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "importedMeal." + id.uuidString)
    }

    @MainActor func importMeal(_ samples: [HKSampleWithDescription], id: UUID) async throws {
        guard !samples.isEmpty else { throw SharedMeal.ShareError.invalid }
        guard !hasImportedMeal(id), importsInProgress.insert(id).inserted else { throw SharedMeal.ShareError.alreadyAdded }
        defer { importsInProgress.remove(id) }
        // Recover if HealthKit committed the batch just before the app stopped.
        let predicate = HKQuery.predicateForObjects(withMetadataKey: "Dietic Meal Import", allowedValues: [id.uuidString])
        if try await !getCorrelationQuery(for: predicate).isEmpty {
            UserDefaults.standard.set(true, forKey: "importedMeal." + id.uuidString)
            throw SharedMeal.ShareError.alreadyAdded
        }
        let correlations = try samples.map { try foodCorrelation(for: $0, importID: id) }
        try await healthStore.save(correlations)
        UserDefaults.standard.set(true, forKey: "importedMeal." + id.uuidString)
        scheduleDiaryUpdate()
    }

    func HKSampleReturn(type: HKQuantityTypeIdentifier, value: Double, quantity: HKUnit, metadata: [String: Any], date: Date) -> HKSample {
        
        return HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: type)!, quantity: HKQuantity(unit: quantity, doubleValue: value), start: date, end: date, metadata: metadata)
        
    }
    
    func loggedDays(from start: Date, until end: Date) async throws -> Set<Date> {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let records = try await getCorrelationQuery(for: predicate, requireAccess: true)
        return Set(records.filter { $0.startDate < end }.map { Calendar.current.startOfDay(for: $0.startDate) })
    }

    func diaryEntries(from start: Date, until end: Date) async throws -> [HKSampleWithDescription] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let results = try await getCorrelationQuery(for: predicate, requireAccess: true)
        return mealSamples(from: results).filter { $0.date >= start && $0.date < end }
            .sorted { $0.date == $1.date ? $0.uuid < $1.uuid : $0.date > $1.date }
    }

    //Read Correlation Samples
    private func getCorrelationQuery(for predicate: NSPredicate, requireAccess: Bool = false) async throws -> [HKCorrelation] {
        return try await withCheckedThrowingContinuation { continuation in
            let foodType = HKCorrelationType.correlationType(forIdentifier: .food)!
            let myAppPredicate = HKQuery.predicateForObjects(from: HKSource.default()) //This retrieve's only my app
                                                                                       //            let notMyAppPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: myAppPredicate) // This would retrieve everything aside from my app
            let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, myAppPredicate])
            let correlationQuery = HKCorrelationQuery(type: foodType, predicate: queryPredicate, samplePredicates: nil) { query, results, error in
                if let error, (error as? HKError)?.code != .errorNoData, requireAccess || !Self.isEmptyRead(error) {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results ?? [])
                }
            }
            healthStore.execute(correlationQuery)
        }
    }
    
    
    //Manipulating the results from the Correlation Query
    private func mealSamples(from results: [HKCorrelation]) -> [HKSampleWithDescription] {
        let dictionaryForHKQuantity: [HKQuantityTypeIdentifier: Int] = [
            .dietaryProtein:203,
            .dietaryFatTotal:204,
            .dietaryCarbohydrates:205,
            .dietaryEnergyConsumed:208,
            .dietaryCaffeine:262,
            .dietarySugar:269,
            .dietaryFiber:291,
            .dietaryCalcium:301,
            .dietaryIron:303,
            .dietaryMagnesium:304,
            .dietaryPhosphorus:305,
            .dietaryPotassium:306,
            .dietarySodium:307,
            .dietaryZinc:309,
            .dietaryCopper:312,
            .dietaryManganese:315,
            .dietarySelenium:317,
            .dietaryVitaminA:320,
            .dietaryVitaminE:323,
            .dietaryVitaminD:328,
            .dietaryVitaminC:401,
            .dietaryThiamin:404,
            .dietaryRiboflavin:405,
            .dietaryNiacin:406,
            .dietaryVitaminB6:415,
            .dietaryFolate:417,
            .dietaryVitaminB12:418,
            .dietaryVitaminK:430,
            .dietaryCholesterol:601,
            .dietaryFatSaturated:606,
            .dietaryFatMonounsaturated:645,
            .dietaryFatPolyunsaturated:646
        ]
        
        return results.compactMap { currentData in
            let nutrientIDs = dictionaryForHKQuantity.compactMap { type, id in
                currentData.objects(for: HKQuantityType(type)).isEmpty ? nil : id
            }.sorted()
            guard let foodName = currentData.metadata?["Food Name"] as? String,
                  let brandName = currentData.metadata?["Brand Name"] as? String,
                  let servingQuantity = currentData.metadata?["Serving Quantity"] as? Double,
                  let servingUnit = currentData.metadata?["Serving Unit"] as? String,
                  let servingWeightGrams = currentData.metadata?["Serving Weight Grams"] as? Double,
                  let mealPeriod = currentData.metadata?["Meal Period"] as? String,
                  let numberOfServings = currentData.metadata?["Number Of Servings"] as? Double,
                  let servingSelection = currentData.metadata?["Serving Selection"] as? String,
                  let uuid = currentData.metadata?[HKMetadataKeyFoodType] as? String else { return nil }
            let time = currentData.startDate
            let calories = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!).first as? HKQuantitySample
            let sugars = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySugar)!).first as? HKQuantitySample
            let totalFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!).first as? HKQuantitySample
            let saturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatSaturated)!).first as? HKQuantitySample
            let cholesterol = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCholesterol)!).first as? HKQuantitySample
            let sodium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySodium)!).first as? HKQuantitySample
            let totalCarbohydrate = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!).first as? HKQuantitySample
            let dietaryFiber = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!).first as? HKQuantitySample
            let protein = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!).first as? HKQuantitySample
            let potassium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryPotassium)!).first as? HKQuantitySample
            let calcium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCalcium)!).first as? HKQuantitySample
            let iron = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryIron)!).first as? HKQuantitySample
            let monounsaturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!).first as? HKQuantitySample
            let polyunsaturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!).first as? HKQuantitySample
            let caffeine = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)!).first as? HKQuantitySample
            let copper = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCopper)!).first as? HKQuantitySample
            let folate = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFolate)!).first as? HKQuantitySample
            let magnesium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryMagnesium)!).first as? HKQuantitySample
            let manganese = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryManganese)!).first as? HKQuantitySample
            let niacin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryNiacin)!).first as? HKQuantitySample
            let phosphorus = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryPhosphorus)!).first as? HKQuantitySample
            let riboflavin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryRiboflavin)!).first as? HKQuantitySample
            let selenium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySelenium)!).first as? HKQuantitySample
            let thiamin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryThiamin)!).first as? HKQuantitySample
            let vitaminA = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminA)!).first as? HKQuantitySample
            let vitaminC = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminC)!).first as? HKQuantitySample
            let vitaminB6 = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB6)!).first as? HKQuantitySample
            let vitaminB12 = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB12)!).first as? HKQuantitySample
            let vitaminD = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!).first as? HKQuantitySample
            let vitaminE = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminE)!).first as? HKQuantitySample
            let vitaminK = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminK)!).first as? HKQuantitySample
            let zinc = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryZinc)!).first as? HKQuantitySample
            

            return HKSampleWithDescription(foodName: foodName,
                                                      brandName: brandName,
                                                      servingQuantity: servingQuantity,
                                                      servingUnit: servingUnit,
                                                      servingWeightGrams: servingWeightGrams,
                                                      calories: calories?.quantity.doubleValue(for: .kilocalorie()) ?? 0,
                                                      sugars: sugars?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      totalFat: totalFat?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      saturatedFat: saturatedFat?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      cholesterol: cholesterol?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      sodium: sodium?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      totalCarbohydrate: totalCarbohydrate?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      dietaryFiber: dietaryFiber?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      protein: protein?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      potassium: potassium?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      calcium: calcium?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      iron: iron?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      monounsaturatedFat: monounsaturatedFat?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      polyunsaturatedFat: polyunsaturatedFat?.quantity.doubleValue(for: .gram()) ?? 0,
                                                      caffeine: caffeine?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      copper: copper?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      folate: folate?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      magnesium: magnesium?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      manganese: manganese?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      niacin: niacin?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      phosphorus: phosphorus?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      riboflavin: riboflavin?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      selenium: selenium?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      thiamin: thiamin?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      vitaminA: vitaminA?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      vitaminC: vitaminC?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      vitaminB6: vitaminB6?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      vitaminB12: vitaminB12?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      vitaminD: vitaminD?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      vitaminE: vitaminE?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      vitaminK: vitaminK?.quantity.doubleValue(for: .gramUnit(with: .micro)) ?? 0,
                                                      zinc: zinc?.quantity.doubleValue(for: .gramUnit(with: .milli)) ?? 0,
                                                      mealPeriod: mealPeriod,
                                                      numberOfServings: numberOfServings,
                                                      servingSelection: servingSelection,
                                                      uuid: uuid,
                                                      date: time,
                                                      attrIDArray: nutrientIDs,
                                                      householdServing: currentData.metadata?["Household Serving"] as? String
                                                     )

        }
    }

    //Deleting the correlation object
    func deleteTheCorrelationObject(uuid: String) {
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyFoodType, allowedValues: [uuid])
        var types: [HKSampleType] = Self.quantityIDs.filter { $0.rawValue.hasPrefix("HKQuantityTypeIdentifierDietary") }
            .map { HKQuantityType($0) }
        types.append(HKCorrelationType(.food))
        let group = DispatchGroup()
        for type in types {
            group.enter()
            healthStore.deleteObjects(of: type, predicate: predicate) { _, _, error in
                if let error { print("Meal deletion failed: \(error.localizedDescription)") }
                group.leave()
            }
        }
        group.notify(queue: .main) { Task { @MainActor in self.scheduleDiaryUpdate() } }
    }

    // MARK: - Caloric Calculations
    func BMR(age: Int, weightinPounds: Double, heightinInches: Double) -> Double {
        Self.basalMetabolicRate(age: age, pounds: weightinPounds, inches: heightinInches, male: sex == "Male")
    }

    static func basalMetabolicRate(age: Int, pounds: Double, inches: Double, male: Bool) -> Double {
        4.536 * pounds + 15.88 * inches - 5 * Double(age) + (male ? 5 : -161)
    }
    
    func totalPassive() {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        let hourlyBMR = bmr / 24
        let minuteBMR = hourlyBMR / 60
        let secondBMR = minuteBMR / 60
        let timePassed = Date().timeIntervalSince(Calendar.current.startOfDay(for: todaysDate))
        
        let totalPassiveCalories = timePassed * secondBMR
        passiveCalories = totalPassiveCalories
        //        totalPassiveString = String(format: "%.02f", totalPassiveCalories)
    }
    
    func remainingBMR() -> Int {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        return Int(bmr - passiveCalories)
    }
    
    func fastingBMRtoLbs() -> Double {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        return bmr / 3500
    }
    func totalCaloriesCalculation() {
        totalCalories = passiveCalories + activeCalories
    }
    
    func totalFatLossCalculation() {
        let totalCaloriesburned = totalCalories
        //we know that fat loss doesn't start until 16 hours into a fast.
        //        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        //        let hourlyBMR = bmr / 24
        
        //        if totalCaloriesburned < hourlyBMR * 16 {
        //            fatLoss = 0
        //        } else {
        //            fatLoss = (totalCaloriesburned - (hourlyBMR * 16)) / 3500
        //        }
        //        fatLoss = (totalCaloriesburned - (hourlyBMR * 16)) / 3500
        //If you are at a deficit you are literally using fat. So no need to use BMR in this particular situation.
        
        fatLoss = (totalCaloriesburned - consumedCalories) / 3500
    }
    
    
    
    // MARK: - Week Calculations For Fat Loss
    
    /// - Tag: Caloric FatLoss Variables
    @Published var weekLongFatLoss = 0.0
    @Published var weekLongCaloriesConsumed = 0.0
    @Published var weekLongActiveCalories = 0.0
    var weeklongCaloriesFromEating = [Calorie]()
    var weeklongCaloriesFromWorkout = [Calorie]()
    @Published var wlpassiveCalories = 0.0
    @Published var wltotalCalories = 0.0
    @Published var WeeklyFatLossGoal = 3.44
    
    func WLPercentageGoal() -> Double {
        let goal = WeeklyFatLossGoal
        guard weekLongFatLoss > 0 else { return 0.0}
        guard weekLongFatLoss / goal <= 1.0 else { return 1.0 }
        return weekLongFatLoss / goal
    }
    
    func getWeekLongStats(start: Date) {
        getConsumedCaloriesWL(start: start)
        getActiveCalorieCalculationWL(start: start)
        
    }
    //We need to reuse the all the previous functions to figureout FatLoss but start from the week.
    func getConsumedCaloriesWL(start: Date) {
        weeklongCaloriesFromEating.removeAll()
        getCaloricEnergyWL(start: start) { statisticsCollection in
            self.updateEatenCaloriesWL(start: start, statisticsCollection: statisticsCollection!)
        }
    }
    
    func getCaloricEnergyWL(start: Date, completion: @escaping (HKStatisticsCollection?) -> Void) {
        let eatenEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let anchorDate = Date.mondayAt12AM()
        
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        
        query = HKStatisticsCollectionQuery(quantityType: eatenEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
        
        query!.initialResultsHandler =  { query, statisticsCollection, error in
            completion(statisticsCollection)
        }
        
        healthStore.execute(query!)
    }
    
    func updateEatenCaloriesWL(start: Date, statisticsCollection: HKStatisticsCollection) {
        let endDate = Date()
        
        statisticsCollection.enumerateStatistics(from: start, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .kilocalorie())
            let step = Calorie(calories: count ?? 0, date: statistics.startDate)
            
            DispatchQueue.main.async {
                self.weeklongCaloriesFromEating.append(step)
            }
        }
        eatingCaloriesCalculationWL()
    }
    
    func eatingCaloriesCalculationWL() {
        DispatchQueue.main.async {
            self.weekLongCaloriesConsumed = self.weeklongCaloriesFromEating.map { $0.calories }.reduce(0, +)
        }
    }
    
    func getActiveCalorieCalculationWL(start: Date) {
        weeklongCaloriesFromWorkout.removeAll()
        getActiveEnergyWL(start: start) { statisticsCollection in
            self.updateCaloriesWL(start: start, statisticsCollection: statisticsCollection!)
        }
        
    }
    
    func getActiveEnergyWL(start: Date, completion: @escaping (HKStatisticsCollection?) -> Void) {
        let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let anchorDate = Date.mondayAt12AM()
        
        let daily = DateComponents(day: 1)
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        
        query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
        
        query!.initialResultsHandler = { query, statisticsCollection, error in
            completion(statisticsCollection)
        }
        
        healthStore.execute(query!)
    }
    
    func updateCaloriesWL(start: Date,statisticsCollection: HKStatisticsCollection) {
        let endDate = Date()
        
        statisticsCollection.enumerateStatistics(from: start, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .kilocalorie())
            let step = Calorie(calories: count ?? 0, date: statistics.startDate)
            
            DispatchQueue.main.async {
                self.weeklongCaloriesFromWorkout.append(step)
            }
        }
        activeCaloriesCalculationWL()
    }
    
    func activeCaloriesCalculationWL() {
        DispatchQueue.main.async {
            self.weekLongActiveCalories = self.weeklongCaloriesFromWorkout.map { $0.calories }.reduce(0, +)
        }
    }
    
    func totalPassiveWL() {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        let hourlyBMR = bmr / 24
        let minuteBMR = hourlyBMR / 60
        let secondBMR = minuteBMR / 60
        let timePassed = Date().timeIntervalSince(Date.mondayAt12AM())
        
        let totalPassiveCalories = timePassed * secondBMR
        wlpassiveCalories = totalPassiveCalories
        //        totalPassiveString = String(format: "%.02f", totalPassiveCalories)
    }
    
    func totalCaloriesCalculationWL() {
        wltotalCalories = wlpassiveCalories + weekLongActiveCalories
    }
    
    func totalFatLossCalculationWL() {
        let totalCaloriesburned = wltotalCalories
        //we know that fat loss doesn't start until 16 hours into a fast.
        //        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        //        let hourlyBMR = bmr / 24
        
        //        if totalCaloriesburned < hourlyBMR * 16 {
        //            fatLoss = 0
        //        } else {
        //            fatLoss = (totalCaloriesburned - (hourlyBMR * 16)) / 3500
        //        }
        //        fatLoss = (totalCaloriesburned - (hourlyBMR * 16)) / 3500
        //If you are at a deficit you are literally using fat. So no need to use BMR in this particular situation.
        
        weekLongFatLoss = (totalCaloriesburned - weekLongCaloriesConsumed) / 3500
    }
    
    // MARK: - Calories Remaining
    
    func caloriesRemaining() async {
        await MainActor.run {
            remainingCalories = caloricConsumptionGoal - consumedCalories + activeCalories
            let result = (consumedCalories - activeCalories) / caloricConsumptionGoal
            if result > 1 {
                percentageOfCaloriesRemaining = 1
            } else {
                if result < 0 {
                    percentageOfCaloriesRemaining = 0
                } else {
                    percentageOfCaloriesRemaining = (consumedCalories - activeCalories) / caloricConsumptionGoal
                }
            }
        }
    }
    
    func caloriesGoalwithDeficit() async {
        await MainActor.run {
            caloricConsumptionGoal = BMR(age: age, weightinPounds: weight, heightinInches: height) - (poundsPerWeekYouWantToLose * 3500 / 7)
        }
    }
    
    func saveGoal() {
        let defaults = UserDefaults.standard
        defaults.set(poundsPerWeekYouWantToLose, forKey: "pounds")
    }
    
}


struct HKSampleWithDescription: Identifiable {
    var id: String { uuid }
    let foodName: String
    let brandName: String
    var servingQuantity: Double
    var servingUnit: String
    var servingWeightGrams: Double
    var calories: Double
    var sugars: Double
    var totalFat: Double
    var saturatedFat: Double
    var cholesterol: Double
    var sodium: Double
    var totalCarbohydrate: Double
    var dietaryFiber: Double
    var protein: Double
    var potassium: Double
    var calcium: Double
    var iron: Double
    var monounsaturatedFat: Double
    var polyunsaturatedFat: Double
    var caffeine: Double
    var copper: Double
    var folate: Double
    var magnesium: Double
    var manganese: Double
    var niacin: Double
    var phosphorus: Double
    var riboflavin: Double
    var selenium: Double
    var thiamin: Double
    var vitaminA: Double
    var vitaminC: Double
    var vitaminB6: Double
    var vitaminB12: Double
    var vitaminD: Double
    var vitaminE: Double
    var vitaminK: Double
    var zinc: Double
    var mealPeriod: String
    var numberOfServings: Double
    var servingSelection: String
    var uuid: String
    var date: Date
    var attrIDArray: [Int]
    var householdServing: String? = nil

    var portion: FoodPortion {
        FoodPortion(quantity: servingQuantity, unit: servingUnit, grams: servingWeightGrams, household: householdServing)
    }
}

enum EatingTime: CustomStringConvertible, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var description: String {
        switch self {
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snack"
        }
    }
}

enum WorkoutPlan: CustomStringConvertible, CaseIterable {
    case weightGain
    case maintain
    case weightLoss
    
    
    var description: String {
        switch self {
            case .weightGain: return "Weight Gain"
            case .maintain: return "Maintain"
            case .weightLoss: return "Weight Loss"
        }
    }
}

enum ServingType: CaseIterable {
    case serving
    case gram
    
    var description: String {
        switch self {
            case .serving: return "Serving"
            case .gram: return "Per gram"
        }
    }
}

extension String {
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// HealthKit timestamps are immutable. Save the replacement batch before deleting the
// original correlations and their nutrients. Record the IDs first so a relaunch can finish.
extension FastingManager {
    private struct PendingMealMove: Codable {
        let foodIDs: Set<String>
        let destination: Date
        var editID: UUID? = nil
        let originalByReplacement: [UUID: UUID]
    }

    private enum MoveError: LocalizedError {
        case busy, changed, missingNutrition
        var errorDescription: String? {
            switch self {
            case .busy: return "A meal move is finishing. Please try again."
            case .changed: return "The foods in this meal have changed. Reopen the meal and try again."
            case .missingNutrition: return "Allow Dietic to write the nutrients in this meal in Health, then try again."
            }
        }
    }

    private func pendingMoveURL() throws -> URL {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
        return dir.appendingPathComponent("PendingMealMove.json")
    }

    @MainActor private func finishPendingMealMove() async throws -> PendingMealMove? {
        let url = try pendingMoveURL()
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile { return nil }
        let move = try JSONDecoder().decode(PendingMealMove.self, from: data)
        let replacementIDs = Set(move.originalByReplacement.keys)
        let replacements = try await getCorrelationQuery(for: HKQuery.predicateForObjects(with: replacementIDs), requireAccess: true)
        // Only remove originals whose replacements still exist. A crash before save
        // leaves the original meal intact, as does a replacement deleted in Health.
        let sourceIDs = Set(replacements.compactMap { move.originalByReplacement[$0.uuid] })
        if !sourceIDs.isEmpty {
            let originals = try await getCorrelationQuery(for: HKQuery.predicateForObjects(with: sourceIDs), requireAccess: true)
            if !originals.isEmpty { try await deleteMealOriginals(originals) }
        }
        try FileManager.default.removeItem(at: url)
        return sourceIDs.count == replacementIDs.count ? move : nil
    }

    private func deleteMealOriginals(_ originals: [HKCorrelation]) async throws {
        let members = Set(originals.flatMap(\.objects))
        try await healthStore.delete((originals as [HKObject]) + Array(members))
    }

    @MainActor func removeDiaryEntry(id: String) async throws {
        guard !movingMeal else { throw MoveError.busy }
        movingMeal = true
        defer { movingMeal = false; scheduleDiaryUpdate() }
        _ = try await finishPendingMealMove()
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyFoodType, allowedValues: [id])
        let originals = try await getCorrelationQuery(for: predicate, requireAccess: true)
        guard originals.count <= 1 else { throw MoveError.changed }
        if !originals.isEmpty { try await deleteMealOriginals(originals) }
    }

    @MainActor func moveMeal(_ entries: [HKSampleWithDescription], from sourceDay: Date, to destination: Date,
                             timestamp: (Date) -> Date) async throws {
        try await replaceEntries(entries, from: sourceDay, to: destination) { source in
            let foodID = UUID().uuidString
            func metadata(_ original: HKObject) -> [String: Any] {
                var result = original.metadata ?? [:]
                result[HKMetadataKeyFoodType] = foodID
                return result
            }
            guard !source.objects.isEmpty else { throw MoveError.missingNutrition }
            let nutrients = try source.objects.map { object -> HKSample in
                guard let sample = object as? HKQuantitySample,
                      healthStore.authorizationStatus(for: sample.quantityType) == .sharingAuthorized else {
                    throw MoveError.missingNutrition
                }
                return HKQuantitySample(type: sample.quantityType, quantity: sample.quantity,
                                        start: timestamp(sample.startDate), end: timestamp(sample.endDate),
                                        metadata: metadata(sample))
            }
            return HKCorrelation(type: source.correlationType, start: timestamp(source.startDate),
                                 end: timestamp(source.endDate), objects: Set(nutrients), metadata: metadata(source))
        }
    }

    @MainActor func editEntry(_ original: HKSampleWithDescription, replacing updated: HKSampleWithDescription,
                              operationID: UUID) async throws {
        try await replaceEntries([original], from: original.date, to: updated.date, editID: operationID) { source in
            let importID = (source.metadata?["Dietic Meal Import"] as? String).flatMap(UUID.init(uuidString:))
            let replacement = try foodCorrelation(for: updated, importID: importID)
            let originalTypes = Set(source.objects.map(\.sampleType))
            guard originalTypes == Set(replacement.objects.map(\.sampleType)),
                  originalTypes.allSatisfy({ healthStore.authorizationStatus(for: $0) == .sharingAuthorized }) else {
                throw MoveError.missingNutrition
            }
            return replacement
        }
    }

    @MainActor private func replaceEntries(_ entries: [HKSampleWithDescription], from sourceDay: Date,
                                           to destination: Date, editID: UUID? = nil,
                                           makeReplacement: (HKCorrelation) throws -> HKCorrelation) async throws {
        guard !movingMeal else { throw MoveError.busy }
        movingMeal = true
        defer { movingMeal = false; scheduleDiaryUpdate() }
        let ids = Set(entries.map(\.uuid))
        let calendar = Calendar.current
        if let finished = try await finishPendingMealMove(), finished.foodIDs == ids, finished.editID == editID,
           calendar.isDate(finished.destination, inSameDayAs: destination) { return }

        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyFoodType, allowedValues: Array(ids))
        let originals = try await getCorrelationQuery(for: predicate, requireAccess: true)
        guard !ids.isEmpty, originals.count == entries.count,
              Set(originals.compactMap { $0.metadata?[HKMetadataKeyFoodType] as? String }) == ids,
              originals.allSatisfy({ calendar.isDate($0.startDate, inSameDayAs: sourceDay) }) else {
            throw MoveError.changed
        }

        let replacements = try originals.map(makeReplacement)
        let pairs = zip(replacements, originals).map { ($0.uuid, $1.uuid) }
        let move = PendingMealMove(foodIDs: ids, destination: destination, editID: editID,
                                   originalByReplacement: Dictionary(uniqueKeysWithValues: pairs))
        let url = try pendingMoveURL()
        try JSONEncoder().encode(move).write(to: url, options: .atomic)
        try await healthStore.save(replacements)
        try await deleteMealOriginals(originals)
        try FileManager.default.removeItem(at: url)
    }
}
