//
//  Home.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI

struct Home: View {
    @ObservedObject var fastingManager: FastingManager
    @Namespace var namespace
    @State var show = false
    @State var showStatusBar = false
    @State var plusButtonTapped = false
    var body: some View {
        NavigationView {
            ZStack {
                
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                
                if !show {
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            VStack {
                                DietTitle(title: "Mediterranean diet", view: AnyView(DietDetailView()), imageStringText: "Details", imageSystemName: "arrow.right")
                                
                                
                                DietCard(fastingManager: fastingManager)
                                
                                
                                DietTitle(title: "Meals today", view: AnyView(DietDetailView()), imageStringText: "Customize", imageSystemName: "arrow.right")
                                    .padding(.top)
                                
                                
                                MealsToday(fastingManager: fastingManager, namespace: namespace, show: $show, showStatusBar: $showStatusBar)
                                    .zIndex(-1)
                                    
                                    
                                
                                DietTitle(title: "Body measurement", view: AnyView(DietDetailView()), imageStringText: "Today", imageSystemName: "arrow.right")
                                
                                WeightCard(fastingManager: fastingManager)
                            }
                            .padding()
                            
                                
                            
                            
                        }
                    }
                    
                    
                }
                
                if show {
                    MatchedView(fastingManager: fastingManager, namespace: namespace, show: $show, showStatusBar: $showStatusBar)
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeInOut(duration: 0.1)),
                            removal: .opacity.animation(.easeInOut(duration: 0.3))))
                    //                        .rotation3DEffect(show ? Angle(degrees: 180): Angle(degrees: 0), axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
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
            .statusBar(hidden: !showStatusBar)
            .onChange(of: show) { newValue in
                withAnimation(.closeCard) {
                    if newValue {
                        showStatusBar = false
                    } else {
                        showStatusBar = true
                    }
                }
            }
            
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .accentColor(.blue)
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







