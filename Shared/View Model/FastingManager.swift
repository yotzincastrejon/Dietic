//
//  FastingManager.swift
//  Deficit Revised
//
//  Created by Yotzin Castrejon on 4/26/21.
//

import Foundation
import HealthKit
import Combine


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
    var caloriesFromEating = [Calorie]()
    var caloriesFromWorkout = [Calorie]()
    var weight: Double = 0
    var height: Double = 0
    var sex: String = ""
    var age: Int = 0
    var bodyFat: Double = 0
    
    /// - Tag: Macros Calculations
    var carbs = [Calorie]()
    var proteinArray = [Calorie]()
    var fatArray = [Calorie]()
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
    @Published var activeCalories: Double = 0
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
    @Published var day: Int = 0
    @Published var todaysDate = Date.now
    
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
    
    func start() -> Date {
        DispatchQueue.main.async { [self] in
            todaysDate = Calendar.current.date(byAdding: .day, value: day, to: Date.now)!
        }
        return Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: day,to: Date())!)
    }
    
    func end() -> Date {
        return Calendar.current.date(byAdding: .hour, value: 24, to: Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: day,to: Date())!))!
    }
    
    func addDate() {
        day += 1
    }
    
    func subtractDate() {
        day -= 1
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
    
    
    func requestAuthorization() async {
//        let queue = DispatchQueue.global()
//        let group = DispatchGroup()
        
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            typeToRead(type: .bodyFatPercentage),
            typeToRead(type: .dietaryEnergyConsumed),
            typeToRead(type: .dietaryCholesterol),
            typeToRead(type: .dietarySugar),
            typeToRead(type: .dietaryFatTotal),
            typeToRead(type: .dietaryFatSaturated),
            typeToRead(type: .dietarySodium),
            typeToRead(type: .dietaryCarbohydrates),
            typeToRead(type: .dietaryFiber),
            typeToRead(type: .dietaryProtein),
            typeToRead(type: .dietaryPotassium),
            typeToRead(type: .dietaryCalcium),
            typeToRead(type: .dietaryIron),
            typeToRead(type: .dietaryFatMonounsaturated),
            typeToRead(type: .dietaryFatPolyunsaturated),
            typeToRead(type: .dietaryCaffeine),
            typeToRead(type: .dietaryCopper),
            typeToRead(type: .dietaryFolate),
            typeToRead(type: .dietaryMagnesium),
            typeToRead(type: .dietaryManganese),
            typeToRead(type: .dietaryNiacin),
            typeToRead(type: .dietaryPhosphorus),
            typeToRead(type: .dietaryRiboflavin),
            typeToRead(type: .dietarySelenium),
            typeToRead(type: .dietaryThiamin),
            typeToRead(type: .dietaryVitaminA),
            typeToRead(type: .dietaryVitaminC),
            typeToRead(type: .dietaryVitaminB6),
            typeToRead(type: .dietaryVitaminB12),
            typeToRead(type: .dietaryVitaminD),
            typeToRead(type: .dietaryVitaminE),
            typeToRead(type: .dietaryVitaminK),
            typeToRead(type: .dietaryZinc)
        ]
        
        //We can't set the Date of Birth or Sex the user must enter it in the health app. We should deal with missing information another way.
        let typesToShare: Set = [
            typeToSet(type: .activeEnergyBurned),
            typeToSet(type: .bodyMass),
            typeToSet(type: .height),
            typeToSet(type: .bodyFatPercentage),
            typeToSet(type: .dietaryCholesterol),
            typeToSet(type: .dietaryEnergyConsumed),
            typeToSet(type: .dietarySugar),
            typeToSet(type: .dietaryFatTotal),
            typeToSet(type: .dietaryFatSaturated),
            typeToSet(type: .dietarySodium),
            typeToSet(type: .dietaryCarbohydrates),
            typeToSet(type: .dietaryFiber),
            typeToSet(type: .dietaryProtein),
            typeToSet(type: .dietaryPotassium),
            typeToSet(type: .dietaryCalcium),
            typeToSet(type: .dietaryIron),
            typeToSet(type: .dietaryFatMonounsaturated),
            typeToSet(type: .dietaryFatPolyunsaturated),
            typeToSet(type: .dietaryCaffeine),
            typeToSet(type: .dietaryCopper),
            typeToSet(type: .dietaryFolate),
            typeToSet(type: .dietaryMagnesium),
            typeToSet(type: .dietaryManganese),
            typeToSet(type: .dietaryNiacin),
            typeToSet(type: .dietaryPhosphorus),
            typeToSet(type: .dietaryRiboflavin),
            typeToSet(type: .dietarySelenium),
            typeToSet(type: .dietaryThiamin),
            typeToSet(type: .dietaryVitaminA),
            typeToSet(type: .dietaryVitaminC),
            typeToSet(type: .dietaryVitaminB6),
            typeToSet(type: .dietaryVitaminB12),
            typeToSet(type: .dietaryVitaminD),
            typeToSet(type: .dietaryVitaminE),
            typeToSet(type: .dietaryVitaminK),
            typeToSet(type: .dietaryZinc)
        ]
        
        func typeToSet(type: HKQuantityTypeIdentifier) -> HKSampleType {
            return HKQuantityType.quantityType(forIdentifier: type)!
        }
        
        func typeToRead(type: HKQuantityTypeIdentifier) -> HKObjectType {
            return HKObjectType.quantityType(forIdentifier: type)!
        }
        
//        queue.async(group: group) {
//            Task {
//                do {
//                    try await self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
//                } catch {
//                    print("\(error.localizedDescription)")
//                    print(String(describing: error))
//                }
//            }
//        }
//        
//        group.wait()
//        
//        queue.async(group: group) { [self] in
//            Task {
//                try await printTheCorrelation(results: getCorrelationQuery())
//            }
//        }
//        
//        queue.async(group: group) { [self] in
//            Task {
//                await getWeight()
//                await getHeight()
//                await getBodyFat()
//                await loadandDisplayAge()
//                await getActiveEnergy()
//                await getDietaryEnergy()
//                await getProtein()
//                await getFat()
//                await getCarbohydrates()
//            }
//        }
//        
//        group.wait()
//        
////        queue.async(group: group) { [self] in
////            Task {
////                self.getWeekLongStats(start: Date.mondayAt12AM())
////                await caloriesGoalwithDeficit()
////                await caloriesRemaining()
////
////
////            }
////        }
////
////        group.wait()
//        
//        queue.async(group: group) {
//            Task {
//                await MainActor.run {
//                    //                caloriesNeededToReachGoalWeight()
//                    self.determineCaloricStanding()
//                }
//            }
//        }
//        
//        queue.async(group: group) {
//            checkingAuthorization(type: .dietaryProtein)
//            checkingAuthorization(type: .dietaryFatTotal)
//            checkingAuthorization(type: .dietaryCarbohydrates)
//            checkingAuthorization(type: .dietaryEnergyConsumed)
//            checkingAuthorization(type: .dietaryCaffeine)
//            checkingAuthorization(type: .dietarySugar)
//            checkingAuthorization(type: .dietaryFiber)
//            checkingAuthorization(type: .dietaryCalcium)
//            checkingAuthorization(type: .dietaryIron)
//            checkingAuthorization(type: .dietaryMagnesium)
//            checkingAuthorization(type: .dietaryPhosphorus)
//            checkingAuthorization(type: .dietaryPotassium)
//            checkingAuthorization(type: .dietarySodium)
//            checkingAuthorization(type: .dietaryZinc)
//            checkingAuthorization(type: .dietaryCopper)
//            checkingAuthorization(type: .dietaryManganese)
//            checkingAuthorization(type: .dietarySelenium)
//            checkingAuthorization(type: .dietaryVitaminA)
//            checkingAuthorization(type: .dietaryVitaminE)
//            checkingAuthorization(type: .dietaryVitaminD)
//            checkingAuthorization(type: .dietaryVitaminC)
//            checkingAuthorization(type: .dietaryThiamin)
//            checkingAuthorization(type: .dietaryRiboflavin)
//            checkingAuthorization(type: .dietaryNiacin)
//            checkingAuthorization(type: .dietaryVitaminB6)
//            checkingAuthorization(type: .dietaryFolate)
//            checkingAuthorization(type: .dietaryVitaminB12)
//            checkingAuthorization(type: .dietaryVitaminK)
//            checkingAuthorization(type: .dietaryCholesterol)
//            checkingAuthorization(type: .dietaryFatSaturated)
//            checkingAuthorization(type: .dietaryFatMonounsaturated)
//            checkingAuthorization(type: .dietaryFatPolyunsaturated)
//            checkingAuthorization(type: .dietaryProtein)
//            checkingAuthorization(type: .dietaryFatTotal)
//            checkingAuthorization(type: .dietaryCarbohydrates)
//        }
        
        @Sendable func checkingAuthorization(type: HKQuantityTypeIdentifier) {
            if self.healthStore.authorizationStatus(for: HKObjectType.quantityType(forIdentifier: type)!) == .sharingAuthorized {
                print("Permission Granted to \(type)")
            } else {
                print("Permission Denied to \(type)")
            }
        }
        
        do {
                        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
                        try await printTheCorrelation(results: getCorrelationQuery())
            //This order matters!
                        await getWeight()
                        await getHeight()
                        await getBodyFat()
                        await loadandDisplayAge()
                        await getActiveEnergy()
                        await getDietaryEnergy()
                        await getProtein()
                        await getFat()
                        await getCarbohydrates()
//            self.getWeekLongStats(start: Date.mondayAt12AM())
//            await caloriesGoalwithDeficit()
//            await caloriesRemaining()

            await MainActor.run {
                //                caloriesNeededToReachGoalWeight()
                determineCaloricStanding()
            }


        } catch let error {
            print("An error occurred while requesting HealthKit Authorization: \(error.localizedDescription)")
        }
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
    
    func determineCaloricStanding() {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
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
    
    // MARK: - Health Kit Queries
    
    //Reusable query for getting the most recent sample. It takes a sample type of whatever you want to query and returns a recent sample.
    private func queryHealthKitForMostRecentSample(for sampleType: HKSampleType) async throws -> (HKQuantitySample?) {
        return try await withCheckedThrowingContinuation { continuation in
            let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: end(), options: .strictEndDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let limit = 1
            let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (samples?.first as? HKQuantitySample))
                }
            }
            healthStore.execute(sampleQuery)
        }
    }
    
    //FIXME: We need to create a pop up when a user have no data input.
    //Weight
    public func getWeight() async {
        do {
            let sample = try await queryHealthKitForMostRecentSample(for: HKSampleType.quantityType(forIdentifier: .bodyMass)!)
            let weightInPounds = sample?.quantity.doubleValue(for: HKUnit.pound())
            let source = sample?.sourceRevision.source.name
            let start = sample?.startDate
            self.sampleSourceName = source ?? "Placeholder! You have not entered a weight prior to this date."
            self.sampleSourceDate = start ?? Date()
            self.weight = weightInPounds ?? 120
        } catch {
            print("An error occured while querying for Weight: \(error.localizedDescription)")
        }
    }
    
    //Height
    public func getHeight() async {
        do {
            let sample = try await queryHealthKitForMostRecentSample(for: HKSampleType.quantityType(forIdentifier: .height)!)
            let rawHeight = sample?.quantity.doubleValue(for: HKUnit.inch())
            self.height = rawHeight ?? 0
        } catch {
            print("An error occured while querying for Height: \(error.localizedDescription)")
        }
    }
    
    //Body Fat
    public func getBodyFat() async {
        do {
            let sample = try await queryHealthKitForMostRecentSample(for: HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!)
            let rawBFP = sample?.quantity.doubleValue(for: HKUnit.percent())
            self.bodyFat = rawBFP ?? 0
        } catch {
            print("An error occured while querying for Body Fat: \(error.localizedDescription)")
        }
    }
    
    //Age and Sex
    func getAgeandSex() async throws -> (age: Int, biologicalSex: HKBiologicalSex) {
        do {
            let birthdayComponents = try healthStore.dateOfBirthComponents()
            let biologicalSex = try healthStore.biologicalSex()
            
            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year], from: today)
            
            let thisYear = todayDateComponents.year!
            let age = thisYear - birthdayComponents.year!
            
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            return (age, unwrappedBiologicalSex)
        }
    }
    
    func loadandDisplayAge() async {
        do {
            let getAge = try await getAgeandSex()
            age = getAge.age
            sex = getAge.biologicalSex.stringRepresentation
            
            // The cases for biological sex can go as follows in String
            //Unknown
            //Female
            //Male
            //Other
        } catch let error {
            print("error in Load and Display Age \(error.localizedDescription)")
        }
    }
    
    //Active Energy
    public func getActiveEnergy() async {
        do {
            caloriesFromWorkout.removeAll()
            let sample = try await queryActiveEnergy()
            sample!.enumerateStatistics(from: start(), to: end()) { (statistics, stop) in
                let count = statistics.sumQuantity()?.doubleValue(for: .kilocalorie())
                let step = Calorie(calories: count ?? 0, date: statistics.startDate)
                self.caloriesFromWorkout.append(step)
            }
            await MainActor.run {
                self.activeCalories = self.caloriesFromWorkout.map { $0.calories }.reduce(0, +)
            }
        } catch {
            print("An error occured while querying for Active Energy: \(error.localizedDescription)")
        }
    }
    
    
    private func queryActiveEnergy() async throws -> (HKStatisticsCollection?) {
        return try await withCheckedThrowingContinuation { continuation in
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
            let anchorDate = Date.mondayAt12AM()
            let daily = DateComponents(day: 1)
            let predicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
            
            query!.initialResultsHandler = { query, statisticsCollection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (statisticsCollection))
                }
            }
            healthStore.execute(query!)
        }
    }
    
    //Dietary Energy
    public func getDietaryEnergy() async {
        do {
            caloriesFromEating.removeAll()
            let sample = try await queryDietaryEnergy()
            sample!.enumerateStatistics(from: start(), to: end()) { (statistics, stop) in
                let count = statistics.sumQuantity()?.doubleValue(for: .kilocalorie())
                let step = Calorie(calories: count ?? 0, date: statistics.startDate)
                self.caloriesFromEating.append(step)
            }
            await MainActor.run {
                self.consumedCalories = self.caloriesFromEating.map { $0.calories }.reduce(0, +)
                //Here we add simulated calories on top of consumed.
                //                if simulatedCaloriesBool {
                //                    self.consumedCalories += Double(simulatedCalories)
                //                }
            }
        } catch {
            print("An error occured while querying for Active Energy: \(error.localizedDescription)")
        }
    }
    
    
    private func queryDietaryEnergy() async throws -> (HKStatisticsCollection?) {
        return try await withCheckedThrowingContinuation { continuation in
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
            let anchorDate = Date.mondayAt12AM()
            let daily = DateComponents(day: 1)
            let predicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
            
            query!.initialResultsHandler = { query, statisticsCollection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (statisticsCollection))
                }
            }
            healthStore.execute(query!)
        }
    }
    
    //Carbohydrates
    public func getCarbohydrates() async {
        do {
            carbs.removeAll()
            let sample = try await queryCarbohydrates()
            sample!.enumerateStatistics(from: start(), to: end()) { (statistics, stop) in
                let count = statistics.sumQuantity()?.doubleValue(for: .gram())
                let step = Calorie(calories: count ?? 0, date: statistics.startDate)
                self.carbs.append(step)
            }
            await MainActor.run {
                self.carbohydrates = self.carbs.map { $0.calories }.reduce(0, +)
                //Remaining Available Calories = Total cal - Fat in cal - Protein in cal
                let remainingAvailableCalories = caloricConsumptionGoal - ((weight * 0.5)*9) - ((weight * 0.7)*4)
                if remainingAvailableCalories < 0 {
                    carbPercentage = 1
                    carbRemaining = 0
                } else {
                    let inGrams = remainingAvailableCalories / 4
                    carbPercentage = carbohydrates / inGrams
                    carbRemaining = Int(inGrams - carbohydrates)
                }
            }
        } catch {
            print("An error occured while querying for Carbohydrates: \(error.localizedDescription)")
        }
    }
    
    
    private func queryCarbohydrates() async throws -> (HKStatisticsCollection?) {
        return try await withCheckedThrowingContinuation { continuation in
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!
            let anchorDate = Date.mondayAt12AM()
            let daily = DateComponents(day: 1)
            let predicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
            
            query!.initialResultsHandler = { query, statisticsCollection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (statisticsCollection))
                }
            }
            healthStore.execute(query!)
        }
    }
    
    //Protein
    public func getProtein() async {
        do {
            proteinArray.removeAll()
            let sample = try await queryProtein()
            sample!.enumerateStatistics(from: start(), to: end()) { (statistics, stop) in
                let count = statistics.sumQuantity()?.doubleValue(for: .gram())
                let step = Calorie(calories: count ?? 0, date: statistics.startDate)
                self.proteinArray.append(step)
            }
            await MainActor.run {
                self.protein = self.proteinArray.map { $0.calories }.reduce(0, +)
                let result = macroPercentage(multiple: 0.7, currentAmount: protein)
                proteinPercentage = result.percentage
                proteinRemaining = result.remaining
            }
        } catch {
            print("An error occured while querying for Protein: \(error.localizedDescription)")
        }
    }
    
    
    private func queryProtein() async throws -> (HKStatisticsCollection?) {
        return try await withCheckedThrowingContinuation { continuation in
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!
            let anchorDate = Date.mondayAt12AM()
            let daily = DateComponents(day: 1)
            let predicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
            
            query!.initialResultsHandler = { query, statisticsCollection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (statisticsCollection))
                }
            }
            healthStore.execute(query!)
        }
    }
    
    //Fat
    public func getFat() async {
        do {
            fatArray.removeAll()
            let sample = try await queryFat()
            sample!.enumerateStatistics(from: start(), to: end()) { (statistics, stop) in
                let count = statistics.sumQuantity()?.doubleValue(for: .gram())
                let step = Calorie(calories: count ?? 0, date: statistics.startDate)
                self.fatArray.append(step)
            }
            await MainActor.run {
                self.fat = self.fatArray.map { $0.calories }.reduce(0, +)
                let result = macroPercentage(multiple: 0.5, currentAmount: fat)
                fatPercentage = result.percentage
                fatRemaining = result.remaining
            }
        } catch {
            print("An error occured while querying for Fat: \(error.localizedDescription)")
        }
    }
    
    
    private func queryFat() async throws -> (HKStatisticsCollection?) {
        return try await withCheckedThrowingContinuation { continuation in
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!
            let anchorDate = Date.mondayAt12AM()
            let daily = DateComponents(day: 1)
            let predicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            query = HKStatisticsCollectionQuery(quantityType: activeEnergy, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)
            
            query!.initialResultsHandler = { query, statisticsCollection, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (statisticsCollection))
                }
            }
            healthStore.execute(query!)
        }
    }
    
    func macroPercentage(multiple: Double, currentAmount: Double) -> (percentage: Double, remaining: Int) {
        let goal = weight * multiple
        return (currentAmount / goal,Int(goal - currentAmount))
    }
    
    // MARK: - Requesting Instant Response from Nutrionix
    @Published var instantResponse = [InstantSearchModel]()
    func instantRequestToNutrionix(string: String) async {
        var queryString = string
        queryString = queryString.filter { $0.isPunctuation == false }
        queryString = queryString.trimmingCharacters(in: .whitespaces)
        queryString = queryString.replacingOccurrences(of: " ", with: "-")
        
        print("String: \(queryString)")
        let url = URL(string: "https://trackapi.nutritionix.com/v2/search/instant?query=\(queryString)")! //PUT your string
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("f806ed02", forHTTPHeaderField: "x-app-id")
        request.setValue("37f6225583fc587c2f9a3d8e772e865d", forHTTPHeaderField: "x-app-key")
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let safeData = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {                                              // check for fundamental networking error
                      print("error", error ?? "Unknown error")
                      return
                  }
            //            guard response.statusCode != 404  else {                        // check if item is missing or doesn't exist in the database.
            //                print("item is missing/doesn't exist")
            //                DispatchQueue.main.async {
            //                itemIsMissingBool = true
            //                }
            //                return
            //            }
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            
            
            //                    var responseString = String(data: safeData, encoding: .utf8)
            //                    print(responseString)
            //                    responseString = (responseString as! NSString).replacingOccurrences(of: "\"", with: "")
            //                    print(responseString)
            print("We are decoding directly from the response")
            //                    decode(json: data!)
            
            decodeInstantReponse(data: safeData)
            
            //Or the current working model is decodeJSONResponse(json: data!)
        }
        task.resume()
    }
    
    func instantQueryFullRequest(string: String) async {
        let url = URL(string: "https://trackapi.nutritionix.com/v2/search/item?nix_item_id=\(string)")! //PUT your string
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("f806ed02", forHTTPHeaderField: "x-app-id")
        request.setValue("37f6225583fc587c2f9a3d8e772e865d", forHTTPHeaderField: "x-app-key")
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let safeData = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {                                              // check for fundamental networking error
                      print("error", error ?? "Unknown error")
                      return
                  }
            //            guard response.statusCode != 404  else {                        // check if item is missing or doesn't exist in the database.
            //                print("item is missing/doesn't exist")
            //                DispatchQueue.main.async {
            //                itemIsMissingBool = true
            //                }
            //                return
            //            }
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            
            
            //                    var responseString = String(data: safeData, encoding: .utf8)
            //                    print(responseString)
            //                    responseString = (responseString as! NSString).replacingOccurrences(of: "\"", with: "")
            //                    print(responseString)
            print("We are decoding directly from the response")
            //                    decode(json: data!)
            
            decodeJSONResponse(json: safeData)
            DispatchQueue.main.async {
                self.currentScannedItemJSON = safeData
            }
            //Or the current working model is decodeJSONResponse(json: data!)
        }
        task.resume()
    }
    
    func printTest() {
        print("Submitted From Fasting Manager")
    }
    
    
    func decodeInstantReponse(data: Data) {
        DispatchQueue.main.async { [self] in
            do {
                let response = try JSONDecoder().decode(Instant.self,from: data)
                //            print(response)
                //            print(response?.branded)
                //            print(response?.branded?.count)
                instantResponse.removeAll()
                guard response.branded!.count > 0 else { return }
                for i in 0..<((response.branded?.count)!) {
                    let title = response.branded?[i].foodName
                    let brandName = response.branded?[i].brandName
                    let calories = response.branded?[i].nfCalories
                    let id = response.branded?[i].nixItemID
                    instantResponse.append(InstantSearchModel(title: title ?? "", brandName: brandName ?? "" , calories: Int(calories ?? 0), nixID: id ?? ""))
                }
            } catch {
                print(String(describing: error))
            }
        }
    }
    
    // MARK: - Requesting JSON from Nutrionix
    @Published var itemIsMissingBool: Bool = false
    func jsonRequestToNutrionix(upc: String) {
        let url = URL(string: "https://trackapi.nutritionix.com/v2/search/item?upc=\(upc)")! //PUT your URL
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("f806ed02", forHTTPHeaderField: "x-app-id")
        request.setValue("37f6225583fc587c2f9a3d8e772e865d", forHTTPHeaderField: "x-app-key")
        let task = URLSession.shared.dataTask(with: request) { [self] data, response, error in
            guard let safeData = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {                                              // check for fundamental networking error
                      print("error", error ?? "Unknown error")
                      return
                  }
            guard response.statusCode != 404  else {                        // check if item is missing or doesn't exist in the database.
                print("item is missing/doesn't exist")
                DispatchQueue.main.async {
                    self.itemIsMissingBool = true
                }
                return
            }
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            
            
            //                    var responseString = String(data: safeData, encoding: .utf8)
            //                    print(responseString)
            //                    responseString = (responseString as! NSString).replacingOccurrences(of: "\"", with: "")
            //                    print(responseString)
            print("We are decoding directly from the response")
            //                    decode(json: data!)
            
            decodeJSONResponse(json: safeData)
            DispatchQueue.main.async {
                self.currentScannedItemJSON = safeData
            }
            //Or the current working model is decodeJSONResponse(json: data!)
        }
        task.resume()
    }
    @Published var currentScannedItem: HKSampleWithDescription?
    @Published var currentScannedItemJSON: Data?
    var fullNutrientArray = [FullNutrient]()
    
    
    func decodeJSONResponse(json: Data) {
        do {
            let product = try JSONDecoder().decode(GroceryProduct.self, from: json)
            let info = product.foods[0]
            let nutrient = info.fullNutrients
            print("decoding From JSON Response")
            //            print(nutrient)
            fullNutrientArray.removeAll()
            fullNutrientArray = nutrient
            DispatchQueue.main.async { [self] in
                
                
                currentScannedItem = HKSampleWithDescription(foodName: info.foodName ?? "",
                                                             brandName: info.brandName ?? "",
                                                             servingQuantity: info.servingQuantity ?? 0,
                                                             servingUnit: info.servingUnit ?? "",
                                                             servingWeightGrams: info.servingWeightGrams ?? 0,
                                                             calories: info.calories ?? 0,
                                                             sugars: info.sugars ?? 0,
                                                             totalFat: info.totalFat ?? 0,
                                                             saturatedFat: info.saturatedFat ?? 0,
                                                             cholesterol: info.cholesterol ?? 0,
                                                             sodium: info.sodium ?? 0,
                                                             totalCarbohydrate: info.totalCarbohydrate ?? 0,
                                                             dietaryFiber: info.dietaryFiber ?? 0,
                                                             protein: info.protein ?? 0,
                                                             potassium: info.potassium ?? 0,
                                                             calcium: nutrient.filter { $0.attrID == 301 }.map { $0.value }.first ?? 0,
                                                             iron: nutrient.filter { $0.attrID == 303 }.map { $0.value }.first ?? 0,
                                                             monounsaturatedFat: nutrient.filter { $0.attrID == 645 }.map { $0.value }.first ?? 0,
                                                             polyunsaturatedFat: nutrient.filter { $0.attrID == 646 }.map { $0.value }.first ?? 0,
                                                             caffeine: nutrient.filter { $0.attrID == 262 }.map { $0.value }.first ?? 0,
                                                             copper: nutrient.filter { $0.attrID == 312 }.map { $0.value }.first ?? 0,
                                                             folate: nutrient.filter { $0.attrID == 417 }.map { $0.value }.first ?? 0,
                                                             magnesium: nutrient.filter { $0.attrID == 304 }.map { $0.value }.first ?? 0,
                                                             manganese: nutrient.filter { $0.attrID == 315 }.map { $0.value }.first ?? 0,
                                                             niacin: nutrient.filter { $0.attrID == 406 }.map { $0.value }.first ?? 0,
                                                             phosphorus: nutrient.filter { $0.attrID == 305 }.map { $0.value }.first ?? 0,
                                                             riboflavin: nutrient.filter { $0.attrID == 405 }.map { $0.value }.first ?? 0,
                                                             selenium: nutrient.filter { $0.attrID == 317 }.map { $0.value }.first ?? 0,
                                                             thiamin: nutrient.filter { $0.attrID == 404 }.map { $0.value }.first ?? 0,
                                                             vitaminA: nutrient.filter { $0.attrID == 320 }.map { $0.value }.first ?? 0,
                                                             vitaminC: nutrient.filter { $0.attrID == 401 }.map { $0.value }.first ?? 0,
                                                             vitaminB6: nutrient.filter { $0.attrID == 415 }.map { $0.value }.first ?? 0,
                                                             vitaminB12: nutrient.filter { $0.attrID == 418 }.map { $0.value }.first ?? 0,
                                                             vitaminD: nutrient.filter { $0.attrID == 328 }.map { $0.value }.first ?? 0,
                                                             vitaminE: nutrient.filter { $0.attrID == 323 }.map { $0.value }.first ?? 0,
                                                             vitaminK: nutrient.filter { $0.attrID == 430 }.map { $0.value }.first ?? 0,
                                                             zinc: nutrient.filter { $0.attrID == 309 }.map { $0.value }.first ?? 0,
                                                             mealPeriod: "",
                                                             numberOfServings: 1, servingSelection: "",
                                                             uuid: UUID().uuidString, date: Date.now,
                                                             attrIDArray: [Int]()
                )
            }
        } catch {
            print("Decoding the JSON failed \(error.localizedDescription)")
            print(String(describing: error))
        }
    }
    
    func decodeJsonFromCoreData(data: Data) -> HKSampleWithDescription {
        var sample: HKSampleWithDescription?
        do {
            
            let product = try JSONDecoder().decode(GroceryProduct.self, from: data)
            let info = product.foods[0]
            let nutrient = info.fullNutrients
            print("Decoding from JSON provided from Core Data \(info.foodName ?? "")")
            //            print(nutrient)
            fullNutrientArray.removeAll()
            fullNutrientArray = nutrient
            
            
            
            sample =  HKSampleWithDescription(foodName: info.foodName ?? "",
                                              brandName: info.brandName ?? "",
                                              servingQuantity: info.servingQuantity ?? 0,
                                              servingUnit: info.servingUnit ?? "",
                                              servingWeightGrams: info.servingWeightGrams ?? 0,
                                              calories: info.calories ?? 0,
                                              sugars: info.sugars ?? 0,
                                              totalFat: info.totalFat ?? 0,
                                              saturatedFat: info.saturatedFat ?? 0,
                                              cholesterol: info.cholesterol ?? 0,
                                              sodium: info.sodium ?? 0,
                                              totalCarbohydrate: info.totalCarbohydrate ?? 0,
                                              dietaryFiber: info.dietaryFiber ?? 0,
                                              protein: info.protein ?? 0,
                                              potassium: info.potassium ?? 0,
                                              calcium: nutrient.filter { $0.attrID == 301 }.map { $0.value }.first ?? 0,
                                              iron: nutrient.filter { $0.attrID == 303 }.map { $0.value }.first ?? 0,
                                              monounsaturatedFat: nutrient.filter { $0.attrID == 645 }.map { $0.value }.first ?? 0,
                                              polyunsaturatedFat: nutrient.filter { $0.attrID == 646 }.map { $0.value }.first ?? 0,
                                              caffeine: nutrient.filter { $0.attrID == 262 }.map { $0.value }.first ?? 0,
                                              copper: nutrient.filter { $0.attrID == 312 }.map { $0.value }.first ?? 0,
                                              folate: nutrient.filter { $0.attrID == 417 }.map { $0.value }.first ?? 0,
                                              magnesium: nutrient.filter { $0.attrID == 304 }.map { $0.value }.first ?? 0,
                                              manganese: nutrient.filter { $0.attrID == 315 }.map { $0.value }.first ?? 0,
                                              niacin: nutrient.filter { $0.attrID == 406 }.map { $0.value }.first ?? 0,
                                              phosphorus: nutrient.filter { $0.attrID == 305 }.map { $0.value }.first ?? 0,
                                              riboflavin: nutrient.filter { $0.attrID == 405 }.map { $0.value }.first ?? 0,
                                              selenium: nutrient.filter { $0.attrID == 317 }.map { $0.value }.first ?? 0,
                                              thiamin: nutrient.filter { $0.attrID == 404 }.map { $0.value }.first ?? 0,
                                              vitaminA: nutrient.filter { $0.attrID == 320 }.map { $0.value }.first ?? 0,
                                              vitaminC: nutrient.filter { $0.attrID == 401 }.map { $0.value }.first ?? 0,
                                              vitaminB6: nutrient.filter { $0.attrID == 415 }.map { $0.value }.first ?? 0,
                                              vitaminB12: nutrient.filter { $0.attrID == 418 }.map { $0.value }.first ?? 0,
                                              vitaminD: nutrient.filter { $0.attrID == 328 }.map { $0.value }.first ?? 0,
                                              vitaminE: nutrient.filter { $0.attrID == 323 }.map { $0.value }.first ?? 0,
                                              vitaminK: nutrient.filter { $0.attrID == 430 }.map { $0.value }.first ?? 0,
                                              zinc: nutrient.filter { $0.attrID == 309 }.map { $0.value }.first ?? 0,
                                              mealPeriod: "",
                                              numberOfServings: 1, servingSelection: "",
                                              uuid: UUID().uuidString, date: Date.now,
                                              attrIDArray: [Int]()
            )
            
            
            return sample!
        } catch {
            print("Decoding the JSON failed \(error.localizedDescription)")
            print(String(describing: error))
        }
        
        
        return sample ??  HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]())
    }
    
    // MARK: - Eaten Foods Entry
    //Create an empty array to store food samples
    @Published var theSamples = [HKSampleWithDescription]()
    
    
    
    func saveCorrelation(sample: HKSampleWithDescription, editing: Bool) {
        
        let foodType: HKCorrelationType = HKCorrelationType.correlationType(forIdentifier: .food)!
        let foodCorrelationMetadata: [String: Any] = [HKMetadataKeyFoodType: sample.uuid, "Food Name": sample.foodName, "Brand Name": sample.brandName, "Serving Quantity": sample.servingQuantity, "Serving Unit": sample.servingUnit, "Serving Weight Grams":sample.servingWeightGrams, "Meal Period": sample.mealPeriod, "Number Of Servings": sample.numberOfServings, "Serving Selection": sample.servingSelection]
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
        
        
        if editing {
            for i in 0..<sample.attrIDArray.count {
                guard attrIDArray[sample.attrIDArray[i]] != nil else { continue }
                guard healthStore.authorizationStatus(for: attrIDArray[sample.attrIDArray[i]]!.sampleType) == .sharingAuthorized else { continue }
                fromNutrientArray.insert(attrIDArray[sample.attrIDArray[i]]!)
            }
        } else {
            for i in 0..<fullNutrientArray.count {
                guard attrIDArray[fullNutrientArray[i].attrID] != nil else { continue }
                guard healthStore.authorizationStatus(for: attrIDArray[fullNutrientArray[i].attrID]!.sampleType) == .sharingAuthorized else { continue }
                fromNutrientArray.insert(attrIDArray[fullNutrientArray[i].attrID]!)
            }
        }

        let foodCorrelation: HKCorrelation = HKCorrelation(type: foodType, start: sample.date, end: sample.date, objects: fromNutrientArray, metadata: foodCorrelationMetadata)

        healthStore.save(foodCorrelation) { (success, error) in
            if let error = error {
                
                print("Error Saving Correlation Sample \(error.localizedDescription)")
                print(String(describing: error))
            } else {
                print("Success in saving correlation sample")
                DispatchQueue.main.async {
                    self.currentScannedItem = nil
                    self.currentScannedItemJSON = nil
                }
            }
        }
    }
    
    func HKSampleReturn(type: HKQuantityTypeIdentifier, value: Double, quantity: HKUnit, metadata: [String: Any], date: Date) -> HKSample {
        
        return HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: type)!, quantity: HKQuantity(unit: quantity, doubleValue: value), start: date, end: date, metadata: metadata)
        
    }
    
    //Read Correlation Samples
    var correlationQuery: HKCorrelationQuery?
    func getCorrelationQuery() async throws -> ([HKCorrelation]) {
        return try await withCheckedThrowingContinuation { continuation in
            let foodType = HKCorrelationType.correlationType(forIdentifier: .food)!
            let mostRecentPredicate = HKQuery.predicateForSamples(withStart: start(), end: end(), options: .strictStartDate)
            let myAppPredicate = HKQuery.predicateForObjects(from: HKSource.default()) //This retrieve's only my app
                                                                                       //            let notMyAppPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: myAppPredicate) // This would retrieve everything aside from my app
            let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [mostRecentPredicate, myAppPredicate])
            correlationQuery = HKCorrelationQuery(type: foodType, predicate: queryPredicate, samplePredicates: nil) { query, results, error in
                if let error = error {
                    print("Reading correlation query wasn't completed.")
                    continuation.resume(throwing: error)
                } else {
                    print("Success in reading correlation query")
                    continuation.resume(returning: results!)
                }
            }
            healthStore.execute(correlationQuery!)
        }
    }
    
    
    //Manipulating the results from the Correlation Query
    func printTheCorrelation(results: [HKCorrelation]?) async {
        let quantityIdentifierArray: [HKQuantityTypeIdentifier] = [ .dietaryEnergyConsumed,
                                                                    .dietarySugar,
                                                                    .dietaryFatTotal,
                                                                    .dietaryFatSaturated,
                                                                    .dietaryCholesterol,
                                                                    .dietarySodium,
                                                                    .dietaryCarbohydrates,
                                                                    .dietaryFiber,
                                                                    .dietaryProtein,
                                                                    .dietaryPotassium,
                                                                    .dietaryCalcium,
                                                                    .dietaryIron,
                                                                    .dietaryFatMonounsaturated,
                                                                    .dietaryFatPolyunsaturated,
                                                                    .dietaryCaffeine,
                                                                    .dietaryCopper,
                                                                    .dietaryFolate,
                                                                    .dietaryMagnesium,
                                                                    .dietaryManganese,
                                                                    .dietaryNiacin,
                                                                    .dietaryPhosphorus,
                                                                    .dietaryRiboflavin,
                                                                    .dietarySelenium,
                                                                    .dietaryThiamin,
                                                                    .dietaryVitaminA,
                                                                    .dietaryVitaminC,
                                                                    .dietaryVitaminB6,
                                                                    .dietaryVitaminB12,
                                                                    .dietaryVitaminD,
                                                                    .dietaryVitaminE,
                                                                    .dietaryVitaminK,
                                                                    .dietaryZinc]
        
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
        
        DispatchQueue.main.async { [self] in
            var correlationArrayWithAttrID = [Int]()
            correlationArrayWithAttrID.removeAll()
            theSamples.removeAll()
            for i in 0..<results!.count {
                let currentData: HKCorrelation = results![i]
                
                correlationArrayWithAttrID.removeAll()
                for j in 0..<quantityIdentifierArray.count {
                    if !currentData.objects(for: HKQuantityType.quantityType(forIdentifier: quantityIdentifierArray[j])!).isEmpty {
                        correlationArrayWithAttrID.append(dictionaryForHKQuantity[quantityIdentifierArray[j]]!)
                    }
                }
                
                let foodName = currentData.metadata?["Food Name"]
                let brandName = currentData.metadata?["Brand Name"]
                let servingQuantity = currentData.metadata?["Serving Quantity"]
                let servingUnit = currentData.metadata?["Serving Unit"]
                let servingWeightGrams = currentData.metadata?["Serving Weight Grams"]
                let mealPeriod = currentData.metadata?["Meal Period"]
                let numberOfServings = currentData.metadata?["Number Of Servings"]
                let servingSelection = currentData.metadata?["Serving Selection"]
                let uuid = currentData.metadata?[HKMetadataKeyFoodType]
                let time = currentData.startDate
                let calories = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!).first as! HKQuantitySample?
                let sugars = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySugar)!).first as! HKQuantitySample?
                let totalFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal)!).first as! HKQuantitySample?
                let saturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatSaturated)!).first as! HKQuantitySample?
                let cholesterol = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCholesterol)!).first as! HKQuantitySample?
                let sodium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySodium)!).first as! HKQuantitySample?
                let totalCarbohydrate = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates)!).first as! HKQuantitySample?
                let dietaryFiber = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFiber)!).first as! HKQuantitySample?
                let protein = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryProtein)!).first as! HKQuantitySample?
                let potassium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryPotassium)!).first as! HKQuantitySample?
                let calcium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCalcium)!).first as! HKQuantitySample?
                let iron = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryIron)!).first as! HKQuantitySample?
                let monounsaturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!).first as! HKQuantitySample?
                let polyunsaturatedFat = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!).first as! HKQuantitySample?
                let caffeine = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCaffeine)!).first as! HKQuantitySample?
                let copper = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryCopper)!).first as! HKQuantitySample?
                let folate = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryFolate)!).first as! HKQuantitySample?
                let magnesium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryMagnesium)!).first as! HKQuantitySample?
                let manganese = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryManganese)!).first as! HKQuantitySample?
                let niacin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryNiacin)!).first as! HKQuantitySample?
                let phosphorus = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryPhosphorus)!).first as! HKQuantitySample?
                let riboflavin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryRiboflavin)!).first as! HKQuantitySample?
                let selenium = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietarySelenium)!).first as! HKQuantitySample?
                let thiamin = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryThiamin)!).first as! HKQuantitySample?
                let vitaminA = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminA)!).first as! HKQuantitySample?
                let vitaminC = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminC)!).first as! HKQuantitySample?
                let vitaminB6 = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB6)!).first as! HKQuantitySample?
                let vitaminB12 = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminB12)!).first as! HKQuantitySample?
                let vitaminD = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminD)!).first as! HKQuantitySample?
                let vitaminE = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminE)!).first as! HKQuantitySample?
                let vitaminK = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryVitaminK)!).first as! HKQuantitySample?
                let zinc = currentData.objects(for: HKQuantityType.quantityType(forIdentifier: .dietaryZinc)!).first as! HKQuantitySample?
                
                
                theSamples.append(HKSampleWithDescription(foodName: foodName as! String,
                                                          brandName: brandName as! String,
                                                          servingQuantity: servingQuantity as! Double,
                                                          servingUnit: servingUnit as! String,
                                                          servingWeightGrams: servingWeightGrams as! Double,
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
                                                          mealPeriod: mealPeriod as! String,
                                                          numberOfServings: numberOfServings as! Double,
                                                          servingSelection: servingSelection as! String,
                                                          uuid: uuid as! String,
                                                          date: time,
                                                          attrIDArray: correlationArrayWithAttrID
                                                         ))
            }
            
        }
    }
    
    //Deleting the correlation object
    func deleteTheCorrelationObject(uuid: String) {
        let predicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyFoodType, allowedValues: [uuid])
        healthStore.deleteObjects(of: HKCorrelationType.correlationType(forIdentifier: .food)!, predicate: predicate) { success, _, error in
            if success {
                print("Delete of correlation was successful for \(HKCorrelationType.correlationType(forIdentifier: .food)!)")
            } else {
                print("Deletion of correlation failed for \(HKCorrelationType.correlationType(forIdentifier: .food)!)")
            }
        }
        
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryEnergyConsumed)
        correlationObjectDeletion(predicate: predicate, identifier: .dietarySugar)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFatTotal)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFatSaturated)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryCholesterol)
        correlationObjectDeletion(predicate: predicate, identifier: .dietarySodium)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryCarbohydrates)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFiber)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryProtein)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryPotassium)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryIron)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryCalcium)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFatMonounsaturated)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFatPolyunsaturated)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminC)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryCaffeine)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryCopper)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryFolate)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryMagnesium)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryManganese)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryNiacin)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryPhosphorus)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryRiboflavin)
        correlationObjectDeletion(predicate: predicate, identifier: .dietarySelenium)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryThiamin)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminA)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminB6)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminB12)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminD)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminE)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryVitaminK)
        correlationObjectDeletion(predicate: predicate, identifier: .dietaryZinc)
    }
    
    func correlationObjectDeletion(predicate: NSPredicate, identifier: HKQuantityTypeIdentifier) {
        healthStore.deleteObjects(of: HKQuantityType.quantityType(forIdentifier: identifier)!, predicate: predicate) { success, _, error in
            if success {
                print("Delete of correlation was successful for \(HKQuantityType.quantityType(forIdentifier: identifier)!)")
            } else {
                print("Deletion of correlation failed for \(HKQuantityType.quantityType(forIdentifier: identifier)!)")
            }
        }
    }
    
    
    
    
    
    // MARK: - Caloric Calculations
    func BMR(age: Int, weightinPounds: Double, heightinInches: Double) -> Double {
        //For men
        //TODO: We need to differentiate from Men to Women when calculating BMR as it can be different for each group.
        //TODO: Set a switch statement based on possibilities. Also set a fail safe to make sure all data that is necessary to calculate is available.
        
        //The Mifflin - St Jeor BMR Equation
        if sex == "Male" {
            let imperialFormulaForMen = (4.536 * weightinPounds) + (15.88 * heightinInches)
            let imp2 = imperialFormulaForMen - (5.0 * Double(age)) + 5.0
            
            return imp2
        } else {
            let imperialFormulaForWomen = (4.536 * weightinPounds) + (15.88 * heightinInches)
            let imp2 = imperialFormulaForWomen - (5 * Double(age)) - 161
            return imp2
        }
    }
    
    func totalPassive() {
        let bmr = BMR(age: age, weightinPounds: weight, heightinInches: height)
        let hourlyBMR = bmr / 24
        let minuteBMR = hourlyBMR / 60
        let secondBMR = minuteBMR / 60
        let timePassed = Date().timeIntervalSince(start())
        
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
    let id = UUID()
    let foodName: String
    let brandName: String
    let servingQuantity: Double
    let servingUnit: String
    let servingWeightGrams: Double
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
}

struct GroceryProduct: Codable {
    let foods: [Food]
}
// MARK: - Food
struct Food: Codable {
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
    let fullNutrients: [FullNutrient]
    
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

struct FullNutrient: Codable {
    let attrID: Int
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case attrID = "attr_id"
        case value
    }
}


struct Instant: Codable {
    let branded: [Branded]?
    let common: [Common]?
}

struct Branded: Codable {
    let foodName: String?
    let image: String?
    let servingUnit, nixBrandID, brandNameItemName: String?
    let servingQty, nfCalories: Double?
    let brandName: String?
    let brandType: Double?
    let nixItemID: String?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case image
        case servingUnit = "serving_unit"
        case nixBrandID = "nix_brand_id"
        case brandNameItemName = "brand_name_item_name"
        case servingQty = "serving_qty"
        case nfCalories = "nf_calories"
        case brandName = "brand_name"
        case brandType = "brand_type"
        case nixItemID = "nix_item_id"
    }
}

struct Common: Codable {
    let foodName: String?
    let image: String?
    let tagID, tagName: String?
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case image
        case tagID = "tag_id"
        case tagName = "tag_name"
    }
}

struct InstantSearchModel: Identifiable {
    let id = UUID()
    let title: String
    let brandName: String
    let calories: Int
    let nixID: String
}

extension String {
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
