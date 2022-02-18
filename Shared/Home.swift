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
        var body: some View {
        NavigationView {
            ZStack {

                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                
                if !show {
                ScrollView(showsIndicators: false) {
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
                
                if show {
                    MatchedView(fastingManager: fastingManager, namespace: namespace, show: $show, showStatusBar: $showStatusBar)
                        .zIndex(1)
                        .transition(.asymmetric(
                            insertion: .opacity.animation(.easeInOut(duration: 0.1)),
                            removal: .opacity.animation(.easeInOut(duration: 0.3))))
//                        .rotation3DEffect(show ? Angle(degrees: 180): Angle(degrees: 0), axis: (x: CGFloat(0), y: CGFloat(10), z: CGFloat(0)))
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







