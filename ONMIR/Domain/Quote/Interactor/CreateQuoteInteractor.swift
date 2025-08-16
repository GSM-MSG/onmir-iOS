import CoreData
import Foundation

public struct CreateQuoteInteractor: Sendable {
  private let contextManager: any CoreDataStack

  public init(contextManager: any CoreDataStack = ContextManager.shared) {
    self.contextManager = contextManager
  }

  public func callAsFunction(request: Request) async throws {
    try await contextManager.performAndSave { @Sendable context in
      let quoteEntity = QuoteEntity(context: context)
      quoteEntity.content = request.content
      quoteEntity.page = request.page
      
      let book = context.object(with: request.bookObjectID) as! BookEntity
      quoteEntity.book = book

      context.insert(quoteEntity)
    }
  }
}

extension CreateQuoteInteractor {
  public struct Request: Sendable {
    public let content: String
    public let page: Int64
    public let bookObjectID: NSManagedObjectID

    public init(
      content: String,
      page: Int64,
      bookObjectID: NSManagedObjectID
    ) {
      self.content = content
      self.page = page
      self.bookObjectID = bookObjectID
    }
  }
}