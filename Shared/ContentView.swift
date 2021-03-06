//
//  ContentView.swift
//  Shared
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI


struct ContentView: View {
    @StateObject var fastingManager = FastingManager()
    
    
    
    var body: some View {
//        TabView {
            
            Home(fastingManager: fastingManager)
//            .onAppear {
//                Task {
//                await fastingManager.requestAuthorization()
//                }
//            }
            
//                .tabItem { Image(systemName: "house")
//                    Text("Timer")
//                }
            
//            GoalSettings(fastingManager: fastingManager)
//                .tabItem { Image(systemName: "gear")
//                    Text("Settings")
//                }
            //            AddingFoodScreen(fastingManager: fastingManager)
            //                .tabItem { Image(systemName: "gear")
            //                    Text("Adding Food")
            //                }
            
            //           SwiftUIView(fastingManager: fastingManager)
            //                .tabItem { Image(systemName: "gear")
            //                    Text("Test")
            //                }
//        }
        //        .sheet(isPresented: $showSheet, onDismiss: didDismiss) {
        //            WelcomeView(showSheet: $showSheet)
        //        }
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            ContentView()
                .previewDevice("iPhone 8")
        }
        
    }
}
