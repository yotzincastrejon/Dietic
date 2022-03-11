//
//  SwiftUIView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/28/22.
//

import SwiftUI

struct SwiftUIView: View {
    @ObservedObject var fastingManager: FastingManager
    @State var searchText: String = ""
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    Task {
                   await fastingManager.instantRequestToNutrionix(string: "apple")
                    }
                }) {
                    Text("Request")
                }
                
                List(fastingManager.instantResponse) { value in
                    
                    VStack {
                        NavigationLink(destination: JsonResponseView(isShowing: .constant(false), rootIsActive: Binding.constant(true), fastingManager: fastingManager, sample: fastingManager.currentScannedItem ?? HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]())).onAppear {
                            Task {
                            await fastingManager.instantQueryFullRequest(string: value.nixID)
                            }
                            
                        }) {
                                HStack {
                                    VStack {
                                        Text(value.title)
                                        Text(value.brandName)
                                    }
                                    Spacer()
                                    Text("\(value.calories)")
                            }
                        }
                        
                    }
                    
                    
                    
                    //We can add on tap feature if you wished, then since this doesn't contain any more than the face value of the item we'll have to call the server for more information, with the nix_item_id. Like so https://trackapi.nutritionix.com/v2/search/item?nix_item_id=513fc9e73fe3ffd40300109f
                    
                    
                }.listStyle(.plain)
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { value in
//                        if !value.isEmpty && value.count > 3 {
//
//                        Task {
//                            await fastingManager.instantRequestToNutrionix(string: value)
//                        }
//                        }
                        print(value)
                    }
                    .onSubmit(of: .search) {
                        Task {
                            await fastingManager.instantRequestToNutrionix(string: searchText)
                        }
                    }
            }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView(fastingManager: FastingManager())
    }
}


