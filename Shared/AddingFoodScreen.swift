//
//  AddingFoodScreen.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 2/3/22.
//

import SwiftUI

struct AddingFoodScreen: View {
    @State var searchText = ""
    private var eatenFoods = [
        EatenFood(name: "Salmon"),
        EatenFood(name: "Mixed Veggies"),
        EatenFood(name: "Avocado")
    ]

    var body: some View {
         
            VStack {
                
                List {
                    Section(header: Text("Recent")) {
                        ForEach(eatenFoods) { eaten in
                            HStack {
                                Text("\(eaten.name)")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(Int.random(in: 100..<600)) kcal")
                                    .foregroundColor(Color(red: 0.43529411764705883, green: 0.5607843137254902, blue: 0.9176470588235294))
                                Image(systemName: "plus.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.black, Color(red: 0.9176470588235294, green: 0.9333333333333333, blue: 0.9882352941176471))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText)
            }
            .navigationTitle("Lunch")
            .navigationBarTitleDisplayMode(.inline)
        
        
    }
}

struct AddingFoodScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        AddingFoodScreen()
        }
    }
}

struct EatenFood: Identifiable {
    let name: String
    let id = UUID()
}

