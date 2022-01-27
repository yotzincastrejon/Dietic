//
//  ContentView.swift
//  Shared
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI
import WelcomeSheet

struct ContentView: View {
    @StateObject var fastingManager = FastingManager()
    
    @State private var showSheet = false
        
        let pages = [
            WelcomeSheetPage(title: "Welcome to Welcome Sheet", rows: [
                WelcomeSheetPageRow(imageSystemName: "rectangle.stack.fill.badge.plus",
                                    title: "Quick Creation",
                                    content: "It's incredibly intuitive. Simply declare an array of pages filled with content."),
                
                WelcomeSheetPageRow(imageSystemName: "slider.horizontal.3",
                                    title: "Highly Customisable",
                                    content: "Match sheet's appearance to your app, link buttons, perform actions after dismissal."),
                
                WelcomeSheetPageRow(imageSystemName: "ipad.and.iphone",
                                    title: "Works out of the box",
                                    content: "Don't worry about various screen sizes. It will look gorgeous on every iOS device.")
            ])
        ]
    
    var body: some View {
        TabView {
           
            Home(fastingManager: fastingManager)
                .onAppear {
                    Task {
                        await fastingManager.requestAuthorization()
                    }
                    showSheet.toggle()
                }
                
                .tabItem { Image(systemName: "house")
                    Text("Timer")
                }
            
            GoalSettings(fastingManager: fastingManager)
                .tabItem { Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .welcomeSheet(isPresented: $showSheet, pages: pages)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
