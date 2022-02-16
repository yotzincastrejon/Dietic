//
//  Home.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI

struct Home: View {
    @ObservedObject var fastingManager: FastingManager
        var body: some View {
        NavigationView {
            ZStack {

                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                
                
                ScrollView(showsIndicators: false) {
                    VStack {
                        DietTitle(title: "Mediterranean diet", view: AnyView(DietDetailView()), imageStringText: "Details", imageSystemName: "arrow.right")
                       
                        DietCard(fastingManager: fastingManager)
                            
                        
                        DietTitle(title: "Meals today", view: AnyView(DietDetailView()), imageStringText: "Customize", imageSystemName: "arrow.right")
                            .padding(.top)
                        
                        MealsToday(fastingManager: fastingManager)
                        
                        DietTitle(title: "Body measurement", view: AnyView(DietDetailView()), imageStringText: "Today", imageSystemName: "arrow.right")
                        
                        WeightCard(fastingManager: fastingManager)
                    }
                    .padding()
                }
                
            }
            .navigationTitle("My Diary")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DateChanger(fastingManager: fastingManager)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await fastingManager.requestAuthorization()
                        }
                    }) {
                        Text("Refresh")
                    }
                    
                }
            }
            
          
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Home(fastingManager: FastingManager())
                .preferredColorScheme(.light)
            Home(fastingManager: FastingManager())
                .preferredColorScheme(.dark)
                .previewInterfaceOrientation(.portrait)
        }
    }
}







