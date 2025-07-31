import Accelerate
import Combine
import CoreData
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
  @Published var book: BookEntity?
  @Published var recentReadingLogs: [ReadingLogEntity] = []
  @Published var recentQuotes: [QuoteEntity] = []
  @Published var totalReadingTime: TimeInterval = 0
  @Published var isLoading = false
  @Published var error: Error?
  
  private let contextManager: ContextManager
  
  init(contextManager: ContextManager = ContextManager.shared) {
    self.contextManager = contextManager
  }
  
  func loadBook(with objectID: NSManagedObjectID) {
    isLoading = true
    error = nil
    
    Task {
      do {
        let context = contextManager.mainContext
        
        guard let bookEntity = context.object(with: objectID) as? BookEntity else {
          throw BookDetailError.bookNotFound
        }
        
        self.book = bookEntity
        async let readingLoadsTask: () = loadReadingLogs(for: bookEntity)
        async let quotesTask: () = loadQuotes(for: bookEntity)
        async let readingTimeTask: () = calculateTotalReadingTime(for: bookEntity)
        _ = await (readingLoadsTask, quotesTask, readingTimeTask)
        
        isLoading = false
      } catch {
        self.error = error
        isLoading = false
      }
    }
  }
  
  private func loadReadingLogs(for book: BookEntity) async {
    let sortedLogs = await book.managedObjectContext?.perform { @Sendable in
      let request: NSFetchRequest<ReadingLogEntity> = ReadingLogEntity.fetchRequest()
      request.predicate = NSPredicate(format: "book == %@", book)
      request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingLogEntity.startPage, ascending: false)]
      request.fetchLimit = 3
      
      do {
        return try book.managedObjectContext?.fetch(request) ?? []
      } catch {
        return []
      }
    }
    recentReadingLogs = sortedLogs ?? []
  }
  
  private func loadQuotes(for book: BookEntity) async {
    let sortedQuotes = await book.managedObjectContext?.perform { @Sendable in
      let request: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
      request.predicate = NSPredicate(format: "book == %@", book)
      request.sortDescriptors = [NSSortDescriptor(keyPath: \QuoteEntity.page, ascending: false)]
      request.fetchLimit = 5
      
      do {
        return try book.managedObjectContext?.fetch(request) ?? []
      } catch {
        return []
      }
    }
    recentQuotes = sortedQuotes ?? []
  }
  
  private func calculateTotalReadingTime(for book: BookEntity) async {
    let logs = book.logs?.allObjects as? [ReadingLogEntity] ?? []
    totalReadingTime = logs.reduce(0) { $0 + $1.readingSeconds }
  }
  
  func hasMoreReadingLogs() -> Bool {
    guard let book else { return false }
    return book.managedObjectContext?.performAndWait {
      let request: NSFetchRequest<ReadingLogEntity> = ReadingLogEntity.fetchRequest()
      request.predicate = NSPredicate(format: "book == %@", book)
      do {
        let count = try book.managedObjectContext?.count(for: request) ?? 0
        return count > 3
      } catch {
        return false
      }
    } ?? false
  }
  
  func hasMoreQuotes() -> Bool {
    guard let book else { return false }

    return book.managedObjectContext?.performAndWait {
      let request: NSFetchRequest<QuoteEntity> = QuoteEntity.fetchRequest()
      request.predicate = NSPredicate(format: "book == %@", book)
      do {
        let count = try book.managedObjectContext?.count(for: request) ?? 0
        return count > 5
      } catch {
        return false
      }
    } ?? false
  }
}

enum BookDetailError: Error, LocalizedError {
  case bookNotFound
  
  var errorDescription: String? {
    switch self {
    case .bookNotFound:
      return "Cannot found book"
    }
  }
}
