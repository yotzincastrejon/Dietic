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
        .sheet(isPresented: $showingImagePicker) {
            CodeScannerView(codeTypes: [.qr,
                                        .code128,
                                        .code39,
                                        .code39Mod43,
                                        .code93,
                                        .ean13,
                                        .ean8,
                                        .interleaved2of5,
                                        .itf14,
                                        .pdf417,
                                        .upce], simulatedData: "Paul Hudson\npaul@hackingwithswift.com", completion: handleScan)
        }
        .sheet(isPresented: $showingAddingView) {
            JsonResponseView(isShowing: $showingAddingView, fastingManager: fastingManager)
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
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        showingImagePicker = false
        
        switch result {
        case .success(let result):
//            something = result.string
//            request(upc: result.string)
            fastingManager.jsonRequestToNutrionix(upc: result.string)
            showingAddingView = true
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

