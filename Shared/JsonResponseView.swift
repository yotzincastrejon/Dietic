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
    @State var selection = EatingTime.breakfast
    var body: some View {
        NavigationView {
            VStack {
                Picker("Something", selection: $selection) {
                    ForEach(EatingTime.allCases, id: \.self) { value in
                        Text(value.description)
                           
                    }
                }
                .pickerStyle(.segmented)
                Spacer()
                Text(fastingManager.currentScannedItem?.foodName ?? "")
                Text("Calories:\(String(fastingManager.currentScannedItem?.calories ?? 0))cal")
                Spacer()
                   
                    
                
                
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
                        fastingManager.currentScannedItem?.mealPeriod = selection.description
                        fastingManager.saveCorrelation(sample: fastingManager.currentScannedItem!)
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
