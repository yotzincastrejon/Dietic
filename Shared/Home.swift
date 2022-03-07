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
    var body: some View {
        NavigationView {
            ZStack {
                
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            VStack {
                                DietTitle(title: "Mediterranean diet", view: AnyView(DietDetailView()), imageStringText: "Details", imageSystemName: "arrow.right")
                                
                                
                                DietCard(fastingManager: fastingManager)
                                
                                
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
                    
                    
                
                
                
                if plusButtonTapped {
                    
                    Rectangle()
                        .fill(.black).opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
                    
                
                
              
                    ZStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                            Task {
                                                await fastingManager.requestAuthorization()
                                            }
                                            plusButtonTapped.toggle()
                                        }) {
                                            Image(systemName: "plus")
                                                .foregroundColor(Color("D10"))
                                                .rotationEffect(Angle(degrees: plusButtonTapped ? 45 : 0))
                                                .animation(.linear(duration: 0.1), value: plusButtonTapped)
                                        }
                                        .frame(width: 40, height: 40)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                    .modifier(Shadow(level: 1))
                        }
                        
                                
                                //                .padding(.trailing, 25)
//                                        .padding(.bottom, 27) old padding
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







