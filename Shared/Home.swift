//
//  Home.swift
//  Deficit2.0
//
//  Created by Yotzin Castrejon on 10/18/21.
//

import SwiftUI
import CoreData
import UserNotifications

struct Home: View {
    @ObservedObject var fastingManager: FastingManager
    @State var accentColor: Color = .blue
    @State var appear = [false, false, false]
    @Binding var dietGoal: DietGoal
    @Binding var deficitLevel: DietDeficitLevel
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()
                    ScrollView(showsIndicators: false) {
                        ZStack {
                            VStack {
//                                Button {
//                                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
//                                        if success {
//                                            print("All set!")
//                                        } else if let error = error {
//                                            print(error.localizedDescription)
//                                        }
//                                    }
//                                } label: {
//                                     Text("Permission")
//                                }
//
//                                Button {
//                                    let content = UNMutableNotificationContent()
//                                    content.title = "Feed the cat"
//                                    content.subtitle = "It looks hungry"
//                                    content.sound = UNNotificationSound.default
//
//                                    // show this notification five seconds from now
//                                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
//
//                                    // choose a random identifier
//                                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//                                    // add our notification request
//                                    UNUserNotificationCenter.current().add(request)
//                                } label: {
//                                     Text("Schedule Notification")
//                                }
                                DietCard(fastingManager: fastingManager, dietGoal: $dietGoal, deficitLevel: $deficitLevel)

                                
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
            .onAppear {
                Task {
                    fadeIn()
                }
            }
            .ignoresSafeArea()
            
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
            Home(fastingManager: FastingManager(), dietGoal: .constant(.maintaining), deficitLevel: .constant(.normal))
        }
    }
}
