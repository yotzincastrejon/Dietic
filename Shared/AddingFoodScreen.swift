//
//  AddingFoodScreen.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/3/22.
//

import SwiftUI

struct AddingFoodScreen: View {
    @State var searchText = ""
    @ObservedObject var fastingManager: FastingManager
    var eatenFoods = [
        EatenFood(name: "Salmon"),
        EatenFood(name: "Mixed Veggies"),
        EatenFood(name: "Avocado")
    ]

    var body: some View {
         
        NavigationView {
            VStack {
                    HStack {
                    Button(action: {
                        Task {
                        await fastingManager.requestAuthorization()
                        }
                    }) {
                        Text("Refresh")
                    }
                    .padding()
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    Button(action: {
                        fastingManager.saveCorrelation()
                        Task {
                        await fastingManager.requestAuthorization()
                        }
                    }) {
                        Text("Add")
                    }.padding()
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
    //                List {
    //                    Section(header: Text("Recent")) {
    //                        ForEach(eatenFoods) { eaten in
    //                            HStack {
    //                                Text("\(eaten.name)")
    //                                    .fontWeight(.semibold)
    //                                Spacer()
    //                                Text("\(Int.random(in: 100..<600)) kcal")
    //                                    .foregroundColor(Color(red: 0.43529411764705883, green: 0.5607843137254902, blue: 0.9176470588235294))
    //                                Image(systemName: "plus.circle.fill")
    //                                    .symbolRenderingMode(.palette)
    //                                    .foregroundStyle(Color.black, Color(red: 0.9176470588235294, green: 0.9333333333333333, blue: 0.9882352941176471))
    //                            }
    //                        }
    //                    }
    //                }
    //                .listStyle(.insetGrouped)
    //                .searchable(text: $searchText)
                    
                    List {
                        ForEach(fastingManager.theSamples) { sample in
                            HStack {
    //                            Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                                Text("Calorie: \(sample.calories)")
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
                .navigationTitle("Lunch")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                DateChanger(fastingManager: fastingManager)
            }
            }
        }
        
    }
    func delete(at offsets: IndexSet) {
        print("Deleting sample")
        let index = offsets.first
        fastingManager.deleteTheCorrelationObject(uuid: fastingManager.theSamples[index!].meta)
//        healthkitManager.correlationArray.remove(atOffsets: offsets)
//        healthkitManager.deleteIT(uuid: healthkitManager.theSamples[index!].meta["HKMetadataKeySyncIdentifier"] as! String)
        fastingManager.theSamples.remove(atOffsets: offsets)
        Task {
            await fastingManager.requestAuthorization()
        }
    }
}

struct AddingFoodScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddingFoodScreen(fastingManager: FastingManager())
        }
    }
}

struct EatenFood: Identifiable {
    let name: String
    let id = UUID()
}

