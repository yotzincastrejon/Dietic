//
//  Deficit2_0App.swift
//  Shared
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI
import CoreData

@main
struct Dietic: App {
    let persistenceController = PersistenceController.shared
    @State var dietGoal: DietGoal
    @State var deficitLevel: DietDeficitLevel

    init() {
        let storedDietGoalString = UserDefaults.standard.string(forKey: "dietGoal") ?? ""
        let storedDeficitLevelString = UserDefaults.standard.string(forKey: "deficitLevel") ?? ""

        let storedDietGoal = DietGoal(rawValue: storedDietGoalString) ?? .maintaining
        let storedDeficitLevel = DietDeficitLevel(rawValue: storedDeficitLevelString) ?? .normal

        _dietGoal = State(initialValue: storedDietGoal)
        _deficitLevel = State(initialValue: storedDeficitLevel)
    }

    @StateObject var fastingManager = FastingManager()
    var body: some Scene {
        WindowGroup {
            ContentView(fastingManager: fastingManager, dietGoal: $dietGoal, deficitLevel: $deficitLevel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: dietGoal) { value in
                    UserDefaults.standard.set(value.rawValue, forKey: "dietGoal")
                }
                .onChange(of: deficitLevel) { value in
                    UserDefaults.standard.set(value.rawValue, forKey: "deficitLevel")
                }
        }
    }
}


