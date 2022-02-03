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
    // MARK: - Timer Setup
    /// - Tag: TimerSetup
//    var start: Date = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value:  0,to: Date())!)
//    var end: Date = Date.now
    var cancellable: Cancellable?
    
    func start() -> Date {
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
    //FIX ME WE NEED TO FIX THE SETUP TIMER. IT NEEDS TO BE SETUP EVERYTIME THE APP OPENS. BUT AVOID UPDATING THINGS IF THE STATE OF FASTING IS NOT RUNNING
    // Set up and start the timer.
    func setUpTimer() {
        //        start = Date()
        cancellable = Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.elapsedSeconds >= 86400 {
//                    self.start = Calendar.current.startOfDay(for: Date())
                }
//                self.elapsedSeconds = Int(Date().timeIntervalSince(self.start))
                
                //                self.activeCaloriesCalculation()
                self.totalPassive()
                
                self.totalCaloriesCalculation()
                self.totalFatLossCalculation()
                
                
                self.totalPassiveWL()
                self.totalCaloriesCalculationWL()
                self.totalFatLossCalculationWL()
                
            }
    }
    
    //Originally I had it pounds != nil just incase there is no value. We shall see if this works.
    init() {
        let pounds = UserDefaults.standard.double(forKey: "pounds")
        if pounds != 0 {
            poundsPerWeekYouWantToLose = pounds
        }
        let date = UserDefaults.standard.object(forKey: "Date") as? Date ?? Date()
        if date != Date() {
            futureDate = date
        }
        
        let goalWeightSaved = UserDefaults.standard.integer(forKey: "GoalWeight")
        if goalWeightSaved != 0 {
            goalWeight = goalWeightSaved
        }
        
        let goalBodyFat = UserDefaults.standard.double(forKey: "GoalBodyFatPercentage")
        if goalBodyFat != 0 {
            goalBodyFatPercentage = goalBodyFat
        }
        
        let bool = UserDefaults.standard.bool(forKey: "SimulatedBool")
        if bool == true {
            simulatedCaloriesBool = bool
        }
        
        let simulatedCal = UserDefaults.standard.integer(forKey: "SimulatedCalories")
        if simulatedCal != 0 {
            simulatedCalories = simulatedCal
        }
        
    }
    
    
    func requestAuthorization() async {
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        ]
        
        //We can't set the Date of Birth or Sex the user must enter it in the health app.
        let typesToShare: Set = [
            typeToSet(type: .activeEnergyBurned),
            typeToSet(type: .bodyMass),
            typeToSet(type: .height),
            typeToSet(type: .bodyFatPercentage),
            typeToSet(type: .dietaryEnergyConsumed),
            typeToSet(type: .dietaryCarbohydrates),
            typeToSet(type: .dietaryProtein),
            typeToSet(type: .dietaryFatTotal),
            typeToSet(type: .dietaryFatSaturated),
            typeToSet(type: .dietaryCholesterol),
            typeToSet(type: .dietarySodium),
            typeToSet(type: .dietaryFiber),
            typeToSet(type: .dietarySugar),
            typeToSet(type: .dietaryPotassium)
        ]
        
        func typeToSet(type: HKQuantityTypeIdentifier) -> HKSampleType {
            return HKQuantityType.quantityType(forIdentifier: type)!
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
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
//            self.getConsumedCalories(start: self.start)
            self.getWeekLongStats(start: Date.mondayAt12AM())
            await caloriesGoalwithDeficit()
            await caloriesRemaining()
            
            await MainActor.run {
                caloriesNeededToReachGoalWeight()
            }
          
            
        } catch let error {
            print("An error occurred while requesting HealthKit Authorization: \(error.localizedDescription)")
        }
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
        
        
        let afterMealsAndBurned = finalAmountOfNeededToBurn + eatencalories + Double(simulatedCalories)
        let finalPercentage = burnedCalories / afterMealsAndBurned
        if finalPercentage < 0 {
            percentageAccomplished = 1
        } else {
            percentageAccomplished = burnedCalories / afterMealsAndBurned
        }
        leftToBurn = afterMealsAndBurned - burnedCalories
        dailyDeficitForGoal = perdayCaloriesNeededToLose
        currentDeficitForDay = eatencalories - bmr - burnedCalories
        print("weight to lose: \(weightToLoseInCalories)")
        print("differenceInDays: \(differenceInDays)")
        print("perdayCalories Loss Goal: \(perdayCaloriesNeededToLose)")
        print("After accounting for BMR: \(finalAmountOfNeededToBurn)")
        print("Now Accounting for eaten calories: \(afterMealsAndBurned)")
        print("Left to Burn: \(afterMealsAndBurned - burnedCalories)")
        print("PercentageAccomplished: \(finalPercentage)")
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
    
    //FIX ME: We need to create a pop up when a user have no data input.
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
            print(error)
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


