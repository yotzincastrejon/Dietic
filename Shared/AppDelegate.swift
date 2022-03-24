//
//  AppDelegate.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/22/22.
//

import UIKit
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {
    public var coreDataContext: NSManagedObjectContext!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        coreDataContext = PersistenceController.shared.container.viewContext
        return true
    }
}
