import UIKit
import CoreData

@MainActor
class CoreDataManager {
    static let coreDataManager = CoreDataManager()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "Profile")
            container.loadPersistentStores { storeDescription, error in
                if let error = error as NSError? {
                    print("Unresolved error: \(error)")
                }
            }
            return container
        }()

    var context: NSManagedObjectContext { return self.persistentContainer.viewContext }

    func saveBook(book: Book) -> Bool {
        let entity = NSEntityDescription.entity(forEntityName: "Book", in: self.context)

        if let entity = entity {
            let manageObject = NSManagedObject(entity: entity, insertInto: self.context)
            manageObject.setValue(book.title, forKey: "title")
            manageObject.setValue(book.author, forKey: "author")
            manageObject.setValue(book.book_cover_url, forKey: "book_cover_url")
            manageObject.setValue(book.id, forKey: "id")
            manageObject.setValue(book.quotes, forKey: "quetes")
            manageObject.setValue(book.rating, forKey: "rating")
            manageObject.setValue(book.readType, forKey: "readType")
            manageObject.setValue(book.total_read_time, forKey: "total_read_time")

            do {
                try self.context.save()
                print("저장완료! \(manageObject)")
                return true
            } catch let error {
                print(error)
                return false
            }
        } else {
            return false
        }
    }

    func fetchBook() -> [NSManagedObject] {
        let bookFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Book")
        
        do {
            let fetchResult = try self.context.fetch(bookFetchRequest)
            return fetchResult
        } catch {
            print("책 불러오기 실패 우우ㅠ")
            return []
        }
    }

    func deleteBook(object: NSManagedObject) -> Bool {
        self.context.delete(object)

        do {
            try self.context.save()
            return true
        } catch {
            print("책 삭제 실패")
            return false
        }
    }
}
