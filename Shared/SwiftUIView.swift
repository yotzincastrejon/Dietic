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
                    HStack {
                        Text(value.title)
                        Spacer() 
                        Text("\(value.calories)")
                    }
                    
                }.listStyle(.plain)
                    .searchable(text: $searchText)
                    .onChange(of: searchText) { value in
                        if !value.isEmpty && value.count > 3 {
                           
                        Task {
                            await fastingManager.instantRequestToNutrionix(string: value)
                        }
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


