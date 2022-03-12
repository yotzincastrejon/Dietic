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
    @State var appear = [false, false, false]
    var body: some View {
        ZStack {
            NavigationView {
                    ZStack {
                        
                        Color(uiColor: .systemGroupedBackground)
                            .ignoresSafeArea()
                        
                        
                            ScrollView(showsIndicators: false) {
                                ZStack {
                                    VStack {
                                        
                                        PlanView(isTapped: $isTapped)
                                            .opacity(appear[0] ? 1 : 0)
                                            
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
                                            .opacity(appear[1] ? 1 : 0)
                                        
                                        MealsToday(fastingManager: fastingManager, accentColor: $accentColor)
                                            .zIndex(-1)
                                            .opacity(appear[1] ? 1 : 0)
                                            
                                            
                                        
                                        DietTitle(title: "Body measurement", view: AnyView(DietDetailView()), imageStringText: "Today", imageSystemName: "arrow.right")
                                            .opacity(appear[2] ? 1 : 0)
                                        
                                        WeightCard(fastingManager: fastingManager)
                                            .opacity(appear[2] ? 1 : 0)
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
            .onAppear(perform: {
                Task {
//                    await fastingManager.requestAuthorization()
                    fadeIn()
                }
        })
//            .blur(radius: 14)
            .blur(radius:isTapped ? 10 : 0, opaque: true)
            .saturation(isTapped ? 1.5 : 1)
            .ignoresSafeArea()
            if isTapped {
                        ZStack {
//                            BlurView(effect: .systemUltraThinMaterial)
//                                .ignoresSafeArea()
                            Rectangle()
                                .fill(.white).opacity(0.1)
                                .ignoresSafeArea()
                            VStack(spacing: 10) {
                                Button(action: {
                                    isTapped = false
                                }) {
                                    ZStack {
                                       
                                        Text("Weight Gain")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            
                                    }
                                    .frame(height: 58)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        BlurView(effect: .systemThinMaterialDark)
                                    )
                                .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    isTapped = false
                                }) {
                                    Text("Maintain")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(height: 58)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            BlurView(effect: .systemThinMaterialDark)
                                        )
                                        .clipShape(Capsule())
                                }
                                
                                Button(action: {
                                    isTapped = false
                                }) {
                                    Text("Weight Loss")
                                        .foregroundColor(.white)
                                        .font(.headline)
                                        .frame(height: 58)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            BlurView(effect: .systemThinMaterialDark)
                                        )
                                        .clipShape(Capsule())
                                }
                            
                            }
                            .padding(60)
            
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeInOut(duration: 0.4).delay(0.3)),
                            removal: .opacity.animation(.easeInOut(duration: 0.8).delay(0.6))))
            }
        }
        .onAppear {
            Task {
                await fastingManager.requestAuthorization()
            }
        }
            
            

            
        
    }
    func fadeIn() {
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            appear[0] = true
        }
        withAnimation(.easeOut(duration: 1).delay(0.5)) {
            appear[1] = true
        }
        withAnimation(.easeOut(duration: 1.2).delay(0.7)) {
            appear[2] = true
        }
    }
    
    func fadeOut() {
        appear[0] = false
        appear[1] = false
        appear[2] = false
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







