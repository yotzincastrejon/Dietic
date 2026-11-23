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
    @State private var submittedQuery: String?
    @State private var searchRequest = UUID()
    @State private var matches = [FoodDataCentral.Match]()
    @State private var searchStatus = ""
    @State private var lookup: FoodLookup?
    @State private var isShowingBarcodeView: Bool = false
    @State private var isTorchOn = false
    @State private var dragAmount: CGPoint?
    @State private var showingAddingView = false
    @State private var selectedFood: SavedFood?
    @State private var invalidHistory = false
    @State private var coreDataElement: FetchedResults<SearchedFoods>.Element?
    @State private var addingFromCoreDataIsShowing = false
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
            
            
            
            if submittedQuery == nil {
                List {
                    Section("History") {
                        ForEach(items) { item in
                            ZStack {
                                Button(action: {
                                    Task {
                                        guard let food = SavedFood.readHistory(item.jsonData) else {
                                            invalidHistory = true
                                            return
                                        }
                                        selectedFood = food
                                        coreDataElement = item
                                        addingFromCoreDataIsShowing = true
                                        accentColor = .blue
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(item.name ?? "No Name")")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(Color(uiColor: .label))
                                                .multilineTextAlignment(.leading)
                                            Text("\(item.brandName ??  "No brand")")
                                                .font(.caption2)
                                                .foregroundColor(Color(uiColor: .secondaryLabel))
                                        }
                                        Spacer()
                                        Text("\(Int(item.calories)) kcal")
                                            .font(.subheadline)
                                            .foregroundColor(Color("B10"))
                                        
                                    }
                                    .padding(.leading)
                                    .padding(.trailing, 60)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    
                                }
                                
                                PlusToCheckMark(fastingManager: fastingManager, mealPeriod: mealPeriod, fetched: item)
                                //
                            }
                            
                        }
                        .onDelete(perform: deleteItems)
                        .cornerRadius(10)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(uiColor: .systemGroupedBackground))
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText)
                .onSubmit(of: .search) {
                    submitSearch()

                }
                .onChange(of: searchText, perform: { newValue in
                    items.nsPredicate = newValue.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", newValue)
                })
                
                //                .environment(\.defaultMinListRowHeight, 52)
                //                .frame(minHeight: 52 * CGFloat(items.count))
                .padding(.top, 80)
                BarcodeButton(themeColor: topHeaderColors, isActive: $isShowingBarcodeView)
                
                
                NavigationLink(isActive: $addingFromCoreDataIsShowing) {
                    if let selectedFood, let coreDataElement {
                        FoodServingView(fastingManager: fastingManager, isShowing: $addingFromCoreDataIsShowing,
                                        rootIsActive: $rootIsActive, selection: mealPeriod, food: selectedFood,
                                        historyItem: coreDataElement)
                            .navigationBarBackButtonHidden(true)
                    }
                } label: { EmptyView() }
                .isDetailLink(false)
            } else {
                VStack {
                    List {
                        Section("USDA FoodData Central") {
                            if !searchStatus.isEmpty { Text(searchStatus) }
                            ForEach(matches) { item in
                                Button {
                                    lookup = .food(item.id)
                                    showingAddingView = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(item.description)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.primary)
                                            Text(item.subtitle)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        if let energy = item.energyDescription {
                                            Text(energy)
                                                .font(.subheadline)
                                                .foregroundColor(Color("B10"))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $searchText)
                    .onSubmit(of: .search, submitSearch)
                    .onChange(of: searchText) { value in
                        submittedQuery = nil
                        items.nsPredicate = value.isEmpty ? nil : NSPredicate(format: "name CONTAINS[cd] %@", value)
                    }
                    .task(id: searchRequest) {
                        guard let query = submittedQuery else { return }
                        do {
                            let results = try await FoodDataCentral().search(query)
                            try Task.checkCancellation()
                            matches = results
                            searchStatus = results.isEmpty ? "No matching foods." : ""
                        } catch {
                            if !Task.isCancelled { searchStatus = error.localizedDescription }
                        }
                    }
                    .environment(\.defaultMinListRowHeight, 52)
                    .listStyle(.plain)
                    .padding(.top, 80)
                }
            }
            NavigationLink(isActive: $showingAddingView) {
                if let lookup {
                    FoodLookupView(isShowing: $showingAddingView, rootIsActive: $rootIsActive,
                                     fastingManager: fastingManager, lookup: lookup, mealPeriod: mealPeriod)
                        .navigationBarBackButtonHidden(true)
                }
            } label: { EmptyView() }
        }
        .alert("This saved food could not be read.", isPresented: $invalidHistory) {
            Button("OK") {}
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
                                        .upce],showViewfinder: true, simulatedData: "0016000275287",isTorchOn: isTorchOn, completion: handleScan)
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
    }
    private func submitSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        matches = []
        searchStatus = "Searching…"
        submittedQuery = query
        searchRequest = UUID()
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
                lookup = .barcode(result.string, compressed: result.type == .upce)
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
            
            NavigationView {
                AddMoreFoodView(fastingManager: FastingManager(), mealPeriod: .lunch, topHeaderColors: [Color("B10"), Color("B00")], rootIsActive: Binding.constant(false), accentColor: Binding.constant(.blue))
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                
            }
            
            
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

struct PlusToCheckMark: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var fastingManager: FastingManager
    @State var mealPeriod: EatingTime
    @State var isTapped = false
    @State private var saving = false
    @State private var errorMessage = ""
    @State private var showError = false
    let fetched: SearchedFoods
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                
                guard !saving, !isTapped else { return }
                saving = true
                Task { await addServing() }
            }) {
                ZStack {
                    if isTapped {
                        LottieView(filename: "checkmark", loopMode: .playOnce)
                            .frame(width: 60)
                            .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(uiColor: .systemGray2))
                            Image(systemName: "plus")
                                .font(.system(.body).bold())
                                .foregroundColor(.white)
                            
                        }
                        .frame(width: 30)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))                    }
                }
            }
            
        }
        .padding(.trailing, isTapped ? 5 : 20)
        .alert("Meal log", isPresented: $showError) {
            Button("OK") {}
        } message: { Text(errorMessage) }
    }
    
    @MainActor private func addServing() async {
        defer { saving = false }
        guard let food = SavedFood.readHistory(fetched.jsonData) else {
            errorMessage = "This saved food could not be read."
            showError = true
            return
        }
        do {
            let sample = food.sample(multiplier: 1, quantity: 1, unit: .serving,
                                     meal: mealPeriod, date: fastingManager.mealTimestamp)
            try await fastingManager.saveMeal(sample)
            isTapped = true
            fetched.timestamp = Date()
            try viewContext.save()
        } catch {
            errorMessage = isTapped ? "The meal was logged, but food history could not be updated." : error.localizedDescription
            showError = true
        }
    }
}
