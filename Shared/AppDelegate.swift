//
//  AppDelegate.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/22/22.
//

import UIKit
import CoreData
//import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    public var coreDataContext: NSManagedObjectContext!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted , error in
//            if granted {
//                print("Notifications permission granted")
//            } else {
//                print("Notification permission denied.")
//            }
//        }
//        UNUserNotificationCenter.current().delegate = self
        coreDataContext = PersistenceController.shared.container.viewContext
        return true
    }
}
