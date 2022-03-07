//
//  AddMoreFoodView.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/4/22.
//

import SwiftUI

struct AddMoreFoodView: View {
    @ObservedObject var fastingManager: FastingManager
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \SearchedFoods.timestamp, ascending: false)],
                  animation: .default)
    private var items: FetchedResults<SearchedFoods>
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            VStack {
                RoundedCorners(color: [Color("B10"), Color("B00")], tl: 0, tr: 0, bl: 64, br: 0, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 180)
                Spacer()
            }
            .ignoresSafeArea()
            
            VStack {
                // MARK: - History
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: JsonResponseView(isShowing: Binding.constant(false),fastingManager: fastingManager, sample: fastingManager.decodeJsonFromCoreData(data: item.jsonData!))) {
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
                                            }
                    .onDelete(perform: deleteItems)

                }
                .padding(.top, 200)
            }
            .navigationTitle("Lunch")
        .navigationBarTitleDisplayMode(.inline)
        }
    }
    private func addItem() {
        withAnimation {
            let newItem = SearchedFoods(context: viewContext)
            newItem.timestamp = Date()
            
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
}

struct AddMoreFoodView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            AddMoreFoodView(fastingManager: FastingManager())
        }
    }
}
