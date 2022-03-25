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
        let arrayOfNames = ["Apple", "Peanut Butter", "Grapes"]
        let arrayOfBrand = ["Jif", "Blue Diamond", "Frito Lay"]
        let json = """
        {
          "foods": [
            {
              "food_name": "Organic Refried Beans, Traditional",
              "brand_name": "Rosarita",
              "serving_qty": 0.5,
              "serving_unit": "cup",
              "serving_weight_grams": 123,
              "nf_calories": 110,
              "nf_total_fat": 2,
              "nf_saturated_fat": 1.5,
              "nf_cholesterol": 0,
              "nf_sodium": 550,
              "nf_total_carbohydrate": 17,
              "nf_dietary_fiber": 6,
              "nf_sugars": 0.5,
              "nf_protein": 5,
              "nf_potassium": 370,
              "nf_p": null,
              "full_nutrients": [
                {
                  "attr_id": 203,
                  "value": 5
                },
                {
                  "attr_id": 204,
                  "value": 2
                },
                {
                  "attr_id": 205,
                  "value": 17
                },
                {
                  "attr_id": 208,
                  "value": 110
                },
                {
                  "attr_id": 269,
                  "value": 0.5
                },
                {
                  "attr_id": 291,
                  "value": 6
                },
                {
                  "attr_id": 301,
                  "value": 0
                },
                {
                  "attr_id": 303,
                  "value": 1.6
                },
                {
                  "attr_id": 306,
                  "value": 370
                },
                {
                  "attr_id": 307,
                  "value": 550
                },
                {
                  "attr_id": 324,
                  "value": 0
                },
                {
                  "attr_id": 328,
                  "value": 0
                },
                {
                  "attr_id": 539,
                  "value": 0
                },
                {
                  "attr_id": 601,
                  "value": 0
                },
                {
                  "attr_id": 605,
                  "value": 0
                },
                {
                  "attr_id": 606,
                  "value": 1.5
                }
              ],
              "nix_brand_name": "Rosarita",
              "nix_brand_id": "51db37dd176fe9790a89a12d",
              "nix_item_name": "Organic Refried Beans, Traditional",
              "nix_item_id": "59a26f5a5630511b67c9e7f1",
              "metadata": {},
              "source": 8,
              "ndb_no": null,
              "tags": null,
              "alt_measures": null,
              "lat": null,
              "lng": null,
              "photo": {
                "thumb": "https://nutritionix-api.s3.amazonaws.com/5d75faf6deceaedb7fc518e1.jpeg",
                "highres": null,
                "is_user_uploaded": false
              },
              "note": null,
              "class_code": null,
              "brick_code": null,
              "tag_id": null,
              "updated_at": "2021-03-09T21:21:51+00:00",
              "nf_ingredient_statement": "Cooked Organic Pinto Beans, Water, Less than 2% of: Organic Coconut Oil, Organic Apple Cider Vinegar, Salt, Organic Onion Powder, Organic Cumin, Organic Chili Pepper, Organic Garlic Powder, Organic Rice Fiber, Natural Flavors (Sunflower Oil)"
            }
          ]
        }
        """.data(using: .utf8)
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = SearchedFoods(context: viewContext)
            newItem.timestamp = Date()
            newItem.name = arrayOfNames.randomElement()
            newItem.brandName = arrayOfBrand.randomElement()
            newItem.calories = Double.random(in: 0..<10000)
            newItem.jsonData = json
        }
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
