import SwiftUI

@main
struct Dietic: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var fastingManager = FastingManager()

    var body: some Scene {
        WindowGroup {
            ContentView(fastingManager: fastingManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
