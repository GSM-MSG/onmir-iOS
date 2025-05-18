import Foundation
import CoreData

@MainActor
final class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer
    let context: NSManagedObjectContext

    private init() {
        container = NSPersistentContainer(name: "CoreDataContainer")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
        context = container.viewContext
    }

    func save() {
        do {
            try context.save()
            print("성 ~ 공")
        } catch let error {
            print("실 ~ 패 \(error)")
        }
    }
}
