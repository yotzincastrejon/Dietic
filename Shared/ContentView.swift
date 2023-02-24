//
//  ContentView.swift
//  Shared
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var fastingManager: FastingManager
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    var body: some View {
        Home(fastingManager: fastingManager, dietGoal: $dietGoal, deficitLevel: $deficitLevel)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(fastingManager: FastingManager(), dietGoal: .constant(.maintaining), deficitLevel: .constant(.normal))
        }
    }
}
