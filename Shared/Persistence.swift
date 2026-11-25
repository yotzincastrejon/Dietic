//
//  Persistence.swift
//  Dietic
//
//  Created by Yotzin Castrejon on 3/5/22.
//

import CoreData
import CloudKit

struct PersistenceController {
    static var shared = PersistenceController()
//        let container: NSPersistentCloudKitContainer = {
//            let container = NSPersistentCloudKitContainer(name: "SavedFoodsHistory")
//            container.viewContext.automaticallyMergesChangesFromParent = true
//            container.loadPersistentStores { storeDescription, error in
//                if let error = error as NSError? {
//                    print("Unresolved error \(error), \(error.userInfo)")
//                } else{
//                   print("This was loaded correctly")
//                }
//            }
//            return container
//        }()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let food = SavedFood(name: "Refried Beans", brand: nil, servingQuantity: 0.5,
                             servingUnit: "cup", servingGrams: 123,
                             nutrients: [208: 110, 203: 5, 204: 2, 205: 17])
        let item = SearchedFoods(context: viewContext)
        item.timestamp = Date()
        item.name = food.name
        item.brandName = food.brand
        item.calories = food.nutrients[208] ?? 0
        item.jsonData = try? JSONEncoder().encode(food)
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SavedFoodsHistory")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
    
//    init(inMemory: Bool = false) {
//        container = NSPersistentCloudKitContainer(name: "SavedFoodsHistory")
//
//
//
//        if inMemory {
//            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
//        }
//
//        container.viewContext.automaticallyMergesChangesFromParent = true
//        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
//            if let error = error as NSError? {
//                // Replace this implementation with code to handle the error appropriately.
//                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//
//                /*
//                 Typical reasons for an error here include:
//                 * The parent directory does not exist, cannot be created, or disallows writing.
//                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
//                 * The device is out of space.
//                 * The store could not be migrated to the current model version.
//                 Check the error message to determine what the actual problem was.
//                 */
//                fatalError("Unresolved error \(error), \(error.userInfo)")
//            } else {
//                print("THIS IS THE STORE THAT WAS LOADED")
//            }
//        })
//

    
}

extension SavedFood {
    @MainActor
    func recordHistory(in context: NSManagedObjectContext, updating existing: SearchedFoods? = nil) throws {
        let data = try JSONEncoder().encode(self)
        var match = existing
        if match == nil {
            let request = SearchedFoods.fetchRequest()
            request.predicate = NSPredicate(format: "name == %@", name)
            match = try context.fetch(request).first {
                $0.brandName == brand && SavedFood.readHistory($0.jsonData) == self
            }
        }
        let item = match ?? SearchedFoods(context: context)
        item.timestamp = Date()
        item.name = name
        item.brandName = brand
        item.calories = nutrients[208] ?? 0
        item.jsonData = data
        do {
            try context.save()
        } catch {
            if item.isInserted { context.delete(item) }
            else { context.refresh(item, mergeChanges: false) }
            throw error
        }
    }
}
