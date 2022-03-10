//
//  Home.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI
import CoreData

struct Home: View {
    @ObservedObject var fastingManager: FastingManager
    @State var plusButtonTapped = false
    @State var accentColor: Color = .blue
    @State var isTapped: Bool = false
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()
                    
                    
                        ScrollView(showsIndicators: false) {
                            ZStack {
                                VStack {
                                    PlanView()
    //                                DietTitle(title: "Mediterranean diet", view: AnyView(DietDetailView()), imageStringText: "Details", imageSystemName: "arrow.right")
    //                                    .overlay(
    //                                        VStack {
    //                                            LottieView(filename: "cycling", loopMode: .loop)
    //                                                .frame(width: 100, height: 100)
    //                                                .offset(x: 40, y: -14)
    //                                            Spacer()
    //                                        }
    //                                    )
                                    
                                    DietCard(fastingManager: fastingManager)
                                        
    //                                    .overlay(
    //                                        VStack {
    //                                            Image("RunningMan")
    //                                            .resizable()
    //                                            .aspectRatio(contentMode: .fit)
    //                                        .frame(height: 200)
    //                                        .offset(x: 0, y: -12)
    //                                            Spacer()
    //                                        }
    //                                    )
                                    
                                    DietTitle(title: "Meals today", view: AnyView(DietDetailView()), imageStringText: "Customize", imageSystemName: "arrow.right")
                                        .padding(.top)
                                    
                                    
                                    MealsToday(fastingManager: fastingManager, accentColor: $accentColor)
                                        .zIndex(-1)
                                        
                                        
                                    
                                    DietTitle(title: "Body measurement", view: AnyView(DietDetailView()), imageStringText: "Today", imageSystemName: "arrow.right")
                                    
                                    WeightCard(fastingManager: fastingManager)
                                }
                                .padding()
                                
                                    
                                
                                
                            }
                        }
                        .onAppear {
                            accentColor = .blue
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
        .accentColor(accentColor)
            
            
            ZStack {
                BlurView(effect: .systemUltraThinMaterial)
                    .ignoresSafeArea()
                VStack {
                    PlanView()
                }
                
            }
            
        }
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Home(fastingManager: FastingManager())
                .preferredColorScheme(.light)
            Home(fastingManager: FastingManager())
                .preferredColorScheme(.dark)
            Home(fastingManager: FastingManager())
                .previewDevice("iPhone 8")
                .preferredColorScheme(.dark)
                .previewInterfaceOrientation(.portrait)
            
            
        }
    }
}







