//
//  AddMoreFoodView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/4/22.
//

import SwiftUI
import CoreData
import CodeScanner

struct AddMoreFoodView: View {
    @ObservedObject var fastingManager: FastingManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.isSearching) var isSearching
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SearchedFoods.timestamp, ascending: false)],
                  animation: .default)
    private var items: FetchedResults<SearchedFoods>
    @State var mealPeriod: EatingTime
    @State var topHeaderColors: [Color]
    @Binding var rootIsActive: Bool
    @State private var searchText = ""
    @State private var isSearchingNutritionixDatabase = false
    @State private var isShowingBarcodeView: Bool = false
    @State private var isTorchOn = false
    @State private var dragAmount: CGPoint?
    @State private var showingAddingView = false
    @Binding var accentColor: Color
    init(fastingManager: FastingManager, mealPeriod: EatingTime, topHeaderColors: [Color], rootIsActive: Binding<Bool>, accentColor: Binding<Color>) {
        self.fastingManager = fastingManager
        _mealPeriod = State(initialValue: mealPeriod)
        _topHeaderColors = State(initialValue: topHeaderColors)
        self._rootIsActive = rootIsActive
        self._accentColor = accentColor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = .systemGroupedBackground
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .label
    }
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            SearchableListView(topHeaderColors: topHeaderColors)
                .navigationTitle(mealPeriod.description)
                .navigationBarTitleDisplayMode(.inline)
            
            
            
            if !isSearchingNutritionixDatabase {
                List {
                    Section("History") {
                        ForEach(items) { item in
                            NavigationLink(destination: AddingFromCoreData(selection: mealPeriod, fastingManager: fastingManager, sample: fastingManager.decodeJsonFromCoreData(data: (item.jsonData ?? "".data(using: .utf8))!), shouldPopToRootView: $rootIsActive)
                                .onAppear {
                                    Task {
                                            item.timestamp = Date.now
                                        do {
                                            try viewContext.save()
                                        } catch {
                                            let nsError = error as NSError
                                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                                        }
                                        accentColor = .blue
                                    }
                                }
                                .navigationBarBackButtonHidden(true)
                            ) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(item.name ?? "No Name")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("\(item.brandName ??  "No brand")")
                                            .font(.caption2)
                                            .foregroundColor(Color(uiColor: .secondaryLabel))
                                    }
                                    Spacer()
                                    Text("\(Int(item.calories)) kcal")
                                        .font(.subheadline)
                                        .foregroundColor(Color("B10"))
                                    
                                }
                            }
                            .isDetailLink(false)
                        }
                        .onDelete(perform: deleteItems)
                        
                    }
                    
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
                .onSubmit(of: .search) {
                    Task {
                        print("Submitted")
                        isSearchingNutritionixDatabase = true
                        await fastingManager.instantRequestToNutrionix(string: searchText)
                    }
                    
                }
                .onChange(of: searchText, perform: { newValue in
                    items.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS %@", newValue)
                })
                
                .environment(\.defaultMinListRowHeight, 52)
                //                .frame(minHeight: 52 * CGFloat(items.count))
                .padding(.top, 80)
                
                BarcodeButton(themeColor: topHeaderColors, isActive: $isShowingBarcodeView)
                
                NavigationLink(destination: JsonResponseView(isShowing: $showingAddingView, rootIsActive: $rootIsActive, fastingManager: fastingManager, sample: fastingManager.currentScannedItem ?? HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()), mealPeriod: mealPeriod).navigationBarBackButtonHidden(true), isActive: $showingAddingView, label: { EmptyView() } )
                    
               
            } else {
                // MARK: - Nutrionix Database
                VStack {
                    List {
                        Section("Best Matches") {
                            ForEach(fastingManager.instantResponse) { item in
                                NavigationLink(destination: InstantQueryResponseView(selection: mealPeriod, fastingManager: fastingManager, isShowing: $rootIsActive, sample: fastingManager.currentScannedItem ?? HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]())).onAppear {
                                    Task {
                                        await fastingManager.instantQueryFullRequest(string: item.nixID)
                                    }
                                    
                                }
                                    .navigationBarBackButtonHidden(true)
                                ) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(item.brandName)
                                                .font(.caption2)
                                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                        }
                                        Spacer()
                                        Text("\(Int(item.calories)) kcal")
                                            .font(.subheadline)
                                            .foregroundColor(Color("B10"))
                                        
                                    }
                                }
                                .isDetailLink(false)
                            }
                            .onDelete(perform: deleteItems)
                        }
                        
                    }
                    .onSubmit(of: .search) {
                        Task {
                            await fastingManager.instantRequestToNutrionix(string: searchText)
                        }
                    }
                    .searchable(text: $searchText)
                    .onChange(of: searchText, perform: { newValue in
                        isSearchingNutritionixDatabase = false
                        items.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS %@", newValue)
                    })
                    
                    .environment(\.defaultMinListRowHeight, 52)
                    //                    .frame(minHeight: 52 * CGFloat(fastingManager.instantResponse.count))
                    .listStyle(.plain)
                    .padding(.top, 80)
                }
            }
        }
        .sheet(isPresented: $isShowingBarcodeView) {
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
        //        .sheet(isPresented: $showingAddingView) {
        //            JsonResponseView(isShowing: $showingAddingView, fastingManager: fastingManager, sample: fastingManager.currentScannedItem ?? HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, meta: "", mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()))
        //        }
    }
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingBarcodeView = false
        
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

struct AddMoreFoodView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            TabView {
                NavigationView {
                    AddMoreFoodView(fastingManager: FastingManager(), mealPeriod: .lunch, topHeaderColors: [Color("B10"), Color("B00")], rootIsActive: Binding.constant(false), accentColor: Binding.constant(.blue))
                    
                }
                .tabItem { Image(systemName: "gear")
                    Text("Test")
                }
            }
            
            //            TabView {
            //                NavigationView {
            //                    AddMoreFoodView(fastingManager: FastingManager(), mealPeriod: .breakfast, topHeaderColors: [Color("B10"), Color("B00")], rootIsActive: Binding.constant(false))
            //
            //                }
            //                .tabItem { Image(systemName: "gear")
            //                    Text("Test")
            //                }
            //            }
            //            .previewDevice("iPhone 8")
            
            NavigationView{
                AddingFromCoreData(selection: .lunch, fastingManager: FastingManager(), sample: HKSampleWithDescription(foodName: "", brandName: "", servingQuantity: 0, servingUnit: "", servingWeightGrams: 0, calories: 0, sugars: 0, totalFat: 0, saturatedFat: 0, cholesterol: 0, sodium: 0, totalCarbohydrate: 0, dietaryFiber: 0, protein: 0, potassium: 0, calcium: 0, iron: 0, monounsaturatedFat: 0, polyunsaturatedFat: 0, caffeine: 0, copper: 0, folate: 0, magnesium: 0, manganese: 0, niacin: 0, phosphorus: 0, riboflavin: 0, selenium: 0, thiamin: 0, vitaminA: 0, vitaminC: 0, vitaminB6: 0, vitaminB12: 0, vitaminD: 0, vitaminE: 0, vitaminK: 0, zinc: 0, mealPeriod: "", numberOfServings: 1, servingSelection: "", uuid: "", date: Date.now, attrIDArray: [Int]()), shouldPopToRootView: Binding.constant(false))
            }
        }
        
    }
}


struct AddingFromCoreData: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    private enum Field: Hashable {
        case textField
    }
    @State var selection: EatingTime
    @State var servingTypeSelection = ServingType.serving
    @ObservedObject var fastingManager: FastingManager
    @State var text = "1"
    @State var numberOfServings = 1
    @State var sample: HKSampleWithDescription?
    @Binding var shouldPopToRootView: Bool
    @FocusState private var focusedField: Field?
    var body: some View {
        VStack {
            Picker("", selection: $selection) {
                ForEach(EatingTime.allCases, id: \.self) { value in
                    Text(value.description)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            //            Spacer()
            //            Text(sample?.foodName ?? "")
            //            Text("Calories:\(String(sample?.calories ?? 0))cal")
            
            //            Spacer()
            VStack(spacing: 0) {
                VStack(spacing: 2) {
                    HStack {
                        Text(sample?.foodName ?? "Placeholder")
                            .font(.title3)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Serving size: \(Int(sample?.servingQuantity ?? 0)) \(sample?.servingUnit ?? "g")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    if sample?.servingWeightGrams != 0 {
                        HStack {
                            Text("Serving weight in grams: \(Int(sample?.servingWeightGrams ?? 0))g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                
                if sample?.servingWeightGrams != 0 {
                    Picker("", selection: $servingTypeSelection) {
                        ForEach(ServingType.allCases, id: \.self) { value in
                            Text(value.description)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.top)
                }
                
                HStack(spacing: 15) {
                    if servingTypeSelection == .serving {
                        Text("Number of Servings")
                    } else {
                        Text("Number of grams")
                    }
                    TextField("Text", text: $text)
                        .padding(.leading)
                        .frame(width: 105, height: 44)
                        .background(Capsule().stroke())
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .textField)
                    Spacer()
                }
                .padding(.top, 40)
                Divider()
                    .padding(.top, 24)
                HStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(nutrientCalculation(mainNumber:sample?.calories ?? 0)) kcal")
                            .font(.callout).bold()
                        
                    }
                    
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Carbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:sample?.totalCarbohydrate ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protein")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(nutrientCalculation(mainNumber:sample?.protein ?? 0))g")
                                .font(.callout)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Fat")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            //                            Text("\(Int(Double(sample?.totalFat ?? 0) * (Double(text) ?? 0)))g")
                            //                                .font(.callout)
                            Text("\(nutrientCalculation(mainNumber:sample?.totalFat ?? 0))g")
                                .font(.callout)
                            
                        }
                        Spacer()
                    }
                }
                .padding(.top, 24)
                
                Text("This fruit provides health benefits, high in monounsaturated fat - a \"good\" fat and fiber, that can help you to feel fuller and more satisfied")
                    .padding(16)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .frame(height: 66)
                    .frame(maxWidth: .infinity)
                    .background(Color("B40"))
                    .cornerRadius(8)
                    .padding(.top, 24)
                
                
                HStack(spacing: 15) {
                    Button(action: {
                        fastingManager.currentScannedItem = nil
                        fastingManager.currentScannedItemJSON = nil
                        dismiss()
                    }){
                        Text("Cancel")
                            .fontWeight(.medium)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 48)
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                    .tint(.pink)
                    .background(Capsule().stroke().foregroundColor(.pink))
                    
                    
                    Button(action: {
                        saveNewValue()
                        fastingManager.saveCorrelation(sample: sample!, editing: false)
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                        shouldPopToRootView = false
                    }){
                        Text("Add")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color("B10"),Color("B00")], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .clipShape(Capsule())
                    }
                    
                    
                }
                .padding(.top, 33)
                
            }
            .padding(.horizontal)
            Spacer()
            
            
        }
        .navigationTitle("Adding Food")
        .navigationBarTitleDisplayMode(.inline)
        //        .onTapGesture {
        //            if focusedField != nil {
        //                focusedField = nil
        //            }
        //        }
    }
    
    func nutrientCalculation(mainNumber: Double) -> String {
        if servingTypeSelection == .serving {
            return String(Int(Double(mainNumber) * Double(Double(text) ?? 0)))
        } else {
            return String(Int(Double(mainNumber)/(sample?.servingWeightGrams ?? 1) * Double(Double(text) ?? 0)))
        }
    }
    
    func saveNewValue() {
        if servingTypeSelection == .serving {
            sample?.calories = Double(sample?.calories ?? 0) * (Double(text) ?? 0)
            sample?.sugars = (sample?.sugars ?? 0) * (Double(text) ?? 0)
            sample?.totalFat = Double(sample?.totalFat ?? 0) * (Double(text) ?? 0)
            sample?.saturatedFat = (sample?.saturatedFat ?? 0) * (Double(text) ?? 0)
            sample?.cholesterol = Double(sample?.cholesterol ?? 0) * (Double(text) ?? 0)
            sample?.sodium = Double(sample?.sodium ?? 0) * (Double(text) ?? 0)
            sample?.totalCarbohydrate = Double(sample?.totalCarbohydrate ?? 0) * (Double(text) ?? 0)
            sample?.dietaryFiber = Double(sample?.dietaryFiber ?? 0) * (Double(text) ?? 0)
            sample?.protein = Double(sample?.protein ?? 0) * (Double(text) ?? 0)
            sample?.potassium = Double(sample?.potassium ?? 0) * (Double(text) ?? 0)
            sample?.calcium = Double(sample?.calcium ?? 0) * (Double(text) ?? 0)
            sample?.iron = Double(sample?.iron ?? 0) * (Double(text) ?? 0)
            sample?.monounsaturatedFat = Double(sample?.monounsaturatedFat ?? 0) * (Double(text) ?? 0)
            sample?.polyunsaturatedFat = Double(sample?.polyunsaturatedFat ?? 0) * (Double(text) ?? 0)
            sample?.caffeine = Double(sample?.caffeine ?? 0) * (Double(text) ?? 0)
            sample?.copper = Double(sample?.copper ?? 0) * (Double(text) ?? 0)
            sample?.folate = Double(sample?.folate ?? 0) * (Double(text) ?? 0)
            sample?.magnesium = Double(sample?.magnesium ?? 0) * (Double(text) ?? 0)
            sample?.manganese = Double(sample?.manganese ?? 0) * (Double(text) ?? 0)
            sample?.niacin = Double(sample?.niacin ?? 0) * (Double(text) ?? 0)
            sample?.phosphorus = Double(sample?.phosphorus ?? 0) * (Double(text) ?? 0)
            sample?.riboflavin = Double(sample?.riboflavin ?? 0) * (Double(text) ?? 0)
            sample?.selenium = Double(sample?.selenium ?? 0) * (Double(text) ?? 0)
            sample?.thiamin = Double(sample?.thiamin ?? 0) * (Double(text) ?? 0)
            sample?.vitaminA = Double(sample?.vitaminA ?? 0) * (Double(text) ?? 0)
            sample?.vitaminC = Double(sample?.vitaminC ?? 0) * (Double(text) ?? 0)
            sample?.vitaminB6 = Double(sample?.vitaminB6 ?? 0) * (Double(text) ?? 0)
            sample?.vitaminB12 = Double(sample?.vitaminB12 ?? 0) * (Double(text) ?? 0)
            sample?.vitaminD = Double(sample?.vitaminD ?? 0) * (Double(text) ?? 0)
            sample?.vitaminE = Double(sample?.vitaminE ?? 0) * (Double(text) ?? 0)
            sample?.vitaminK = Double(sample?.vitaminK ?? 0) * (Double(text) ?? 0)
            sample?.zinc = Double(sample?.zinc ?? 0) * (Double(text) ?? 0)
            sample?.numberOfServings = (Double(text) ?? 0)
            sample?.servingSelection = servingTypeSelection.description
            sample?.mealPeriod = selection.description
            sample?.date = fastingManager.todaysDate
        } else {
            let servingWeightGrams = sample?.servingWeightGrams
            sample?.calories = Double(sample?.calories ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.sugars = (sample?.sugars ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.totalFat = Double(sample?.totalFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.saturatedFat = (sample?.saturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.cholesterol = Double(sample?.cholesterol ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.sodium = Double(sample?.sodium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.totalCarbohydrate = Double(sample?.totalCarbohydrate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.dietaryFiber = Double(sample?.dietaryFiber ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.protein = Double(sample?.protein ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.potassium = Double(sample?.potassium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.calcium = Double(sample?.calcium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.iron = Double(sample?.iron ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.monounsaturatedFat = Double(sample?.monounsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.polyunsaturatedFat = Double(sample?.polyunsaturatedFat ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.caffeine = Double(sample?.caffeine ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.copper = Double(sample?.copper ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.folate = Double(sample?.folate ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.magnesium = Double(sample?.magnesium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.manganese = Double(sample?.manganese ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.niacin = Double(sample?.niacin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.phosphorus = Double(sample?.phosphorus ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.riboflavin = Double(sample?.riboflavin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.selenium = Double(sample?.selenium ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.thiamin = Double(sample?.thiamin ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminA = Double(sample?.vitaminA ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminC = Double(sample?.vitaminC ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminB6 = Double(sample?.vitaminB6 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminB12 = Double(sample?.vitaminB12 ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminD = Double(sample?.vitaminD ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminE = Double(sample?.vitaminE ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.vitaminK = Double(sample?.vitaminK ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.zinc = Double(sample?.zinc ?? 0)/(servingWeightGrams ?? 1) * (Double(text) ?? 0)
            sample?.numberOfServings = (Double(text) ?? 0)
            sample?.servingSelection = servingTypeSelection.description
            sample?.mealPeriod = selection.description
            sample?.date = fastingManager.todaysDate
        }
    }
    
}


struct SearchableListView: View {
    @Environment(\.isSearching) var isSearching
    @State var topHeaderColors: [Color]
    @Namespace private var animation
    var body: some View {
        ZStack {
            VStack {
                LinearGradient(colors: topHeaderColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                //                    .opacity(isSearching ? 0.6 : 1)
                    .frame(height: 180)
                    .mask(RoundedCorners(color: topHeaderColors, tl: 0, tr: 0, bl: 64, br: 0, startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Spacer()
            }
            .ignoresSafeArea()
            
            //            if !isSearching {
            //            VStack {
            //                Rectangle()
            //                    .fill(.white)
            //                    .frame(height: 34)
            //                    .cornerRadius(8)
            //                    .offset(x: 0, y: -50)
            //                    .padding(.horizontal, 20)
            //                    .matchedGeometryEffect(id: "Bar", in: animation)
            //
            //                Spacer()
            //            }
            //            } else {
            //                VStack {
            //                    Rectangle()
            //                        .fill(.white)
            //                        .frame(height: 34)
            //                        .cornerRadius(8)
            //                        .offset(x: 0, y: -44)
            //                        .padding(.leading, 20)
            //                        .padding(.trailing, 84)
            //                        .matchedGeometryEffect(id: "Bar", in: animation)
            //                        .transition(.asymmetric(
            //                            insertion: .opacity.animation(.easeInOut(duration: 1).delay(2)),
            //                            removal: .opacity.animation(.easeInOut(duration: 0.3).delay(0.2))))
            //                    Spacer()
            //                }
            //
            //            }
        }
        
        
    }
}
