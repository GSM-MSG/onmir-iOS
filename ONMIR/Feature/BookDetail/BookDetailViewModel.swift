import Foundation
import CoreData
import Combine

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
      let logs = book.logs?.allObjects as? [ReadingLogEntity] ?? []
      return logs.sorted { ($0.startPage) > ($1.startPage) }
    }
    recentReadingLogs = Array((sortedLogs ?? []).prefix(3))
  }
  
  private func loadQuotes(for book: BookEntity) async {
    let sortedQuotes = await book.managedObjectContext?.perform { @Sendable in
      let quotes = book.quotes?.allObjects as? [QuoteEntity] ?? []
      return quotes.sorted { ($0.page) > ($1.page) }
    }
    recentQuotes = Array((sortedQuotes ?? []).prefix(5))
  }
  
  private func calculateTotalReadingTime(for book: BookEntity) async {
    let logs = book.logs?.allObjects as? [ReadingLogEntity] ?? []
    totalReadingTime = logs.reduce(0) { $0 + $1.readingSeconds }
  }
  
  func hasMoreReadingLogs() -> Bool {
    guard let book else { return false }
    return book.managedObjectContext?.performAndWait {
      return book.logs?.count ?? 0 > 3
    } ?? false
  }
  
  func hasMoreQuotes() -> Bool {
    guard let book else { return false }

    return book.managedObjectContext?.performAndWait {
      return book.quotes?.count ?? 0 > 5
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
