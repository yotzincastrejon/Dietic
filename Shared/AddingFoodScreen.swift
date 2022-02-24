//
//  AddingFoodScreen.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/3/22.
//

import SwiftUI
import CodeScanner

struct AddingFoodScreen: View {
    @State var searchText = ""
    @ObservedObject var fastingManager: FastingManager
    @State var showingImagePicker = false
@State var showingAddingView = false
    @State var isTorchOn = false
    @State var dragAmount: CGPoint?
    @State var selection = EatingTime.breakfast
    @State var showingOnTap = false
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
                        //WE will call in a new view to handle scanning
//                        fastingManager.saveCorrelation()
                        Task {
                        await fastingManager.requestAuthorization()
                        }
                    }) {
                        Text("Add")
                    }.padding()
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                Button(action: {
                    showingImagePicker = true
                }) {
                    VStack {
                    Image(systemName: "barcode.viewfinder")
                        .font(.largeTitle)
                    Text("Scan Barcode")
                    }
                }
                .frame(width: 150, height: 150)
                .background(Color(uiColor: .systemGroupedBackground))
                .cornerRadius(20)
                    List {
                        ForEach(fastingManager.theSamples) { sample in
//                            HStack {
//    //                            Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
//                                Text("Calorie: \(sample.calories)")
//
//                            }
                            NavigationLink(destination: EditingResultsView(selection: $selection, fastingManager: fastingManager, isShowing: .constant(false), sample: sample)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(sample.foodName)")
                                            .font(.subheadline)
                                        .fontWeight(.semibold)
                                        Text("\(sample.brandName)")
                                            .font(.caption2)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    Spacer()
                                    Text("\(Int(sample.calories)) kcal")
                                        .font(.subheadline)
                                        .foregroundColor(Color("B10"))
                                    
                                }
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
        .sheet(isPresented: $showingImagePicker) {
            CodeScannerView(codeTypes: [.code128,
                                        .code39,
                                        .code39Mod43,
                                        .code93,
                                        .ean13,
                                        .ean8,
                                        .interleaved2of5,
                                        .itf14,
                                        .pdf417,
                                        .upce],showViewfinder: true, simulatedData: "Paul Hudson\npaul@hackingwithswift.com",isTorchOn: isTorchOn, completion: handleScan)
                .overlay(
                    GeometryReader { g in
                        HStack {
                            Button(action: {
                                isTorchOn.toggle()
                            }) {
                                Image(systemName: isTorchOn ? "lightbulb.circle.fill" : "lightbulb.circle")
                                    .renderingMode(.template)
                                    .resizable()
                                    .foregroundColor(isTorchOn ? .yellow : .gray)
                                    .frame(width: 70, height: 70)
                            }
                            .animation(.linear(duration: 0.15), value: dragAmount)
                            .position(dragAmount ?? CGPoint(x: g.size.width / 2, y: g.size.height / 2))
                            .highPriorityGesture(
                            DragGesture()
                                .onChanged { dragAmount = $0.location }
                            )
                            .offset(y: 200)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                )
        }
        .sheet(isPresented: $showingAddingView) {
            JsonResponseView(isShowing: $showingAddingView, fastingManager: fastingManager, sample: fastingManager.currentScannedItem ?? HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, uuid: "", date: Date.now))
        }
        
//        .sheet(isPresented: $showingOnTap) {
//            AddingFromJSONResultView(selection: $selection, fastingManager: <#T##FastingManager#>, isShowing: <#T##Binding<Bool>#>, sample: <#T##HKSampleWithDescription#>)
//        }
        .navigationViewStyle(StackNavigationViewStyle())

        
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
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        showingImagePicker = false
        
        switch result {
        case .success(let result):
//            something = result.string
//            request(upc: result.string)
            fastingManager.jsonRequestToNutrionix(upc: result.string)
            showingAddingView = true
            print(result.string)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
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

