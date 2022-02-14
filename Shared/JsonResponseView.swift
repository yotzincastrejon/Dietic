//
//  JsonResponseView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/9/22.
//

import SwiftUI

struct JsonResponseView: View {
    @Binding var isShowing: Bool
    @ObservedObject var fastingManager: FastingManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text(fastingManager.currentScannedItem?.foodName ?? "")
                Text("Calories:\(String(fastingManager.currentScannedItem?.calories ?? 0))cal")

            }
            .navigationTitle("We fucking did it!")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading){
                    Button(action: {
                        isShowing = false
                    }){
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        fastingManager.saveCorrelation(sample: fastingManager.currentScannedItem!, mealPeriod: EatingTime.breakfast.description)
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                        isShowing = false
                    }){
                        Text("Add").bold()
                    }
                    
                }
        }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct JsonResponseView_Previews: PreviewProvider {
    static var previews: some View {
        JsonResponseView(isShowing: Binding.constant(true), fastingManager: FastingManager())
    }
}
