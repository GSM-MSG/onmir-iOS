import CoreData
import Foundation

public struct UpdateQuoteInteractor: Sendable {
  private let contextManager: any CoreDataStack

  public init(contextManager: any CoreDataStack = ContextManager.shared) {
    self.contextManager = contextManager
  }

  public func callAsFunction(request: Request) async throws {
    try await contextManager.performAndSave { @Sendable context in
      let quote = context.object(with: request.quoteObjectID) as! QuoteEntity
      quote.content = request.content
      quote.page = request.page
    }
  }
}

extension UpdateQuoteInteractor {
  public struct Request: Sendable {
    public let quoteObjectID: NSManagedObjectID
    public let content: String
    public let page: Int64

    public init(
      quoteObjectID: NSManagedObjectID,
      content: String,
      page: Int64
    ) {
      self.quoteObjectID = quoteObjectID
      self.content = content
      self.page = page
    }
  }
}