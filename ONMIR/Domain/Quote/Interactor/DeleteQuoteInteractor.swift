import CoreData
import Foundation

public struct DeleteQuoteInteractor: Sendable {
  private let contextManager: any CoreDataStack

  public init(contextManager: any CoreDataStack = ContextManager.shared) {
    self.contextManager = contextManager
  }

  public func callAsFunction(request: Request) async throws {
    try await contextManager.performAndSave { @Sendable context in
      for objectID in request.quoteObjectIDs {
        let quote = context.object(with: objectID)
        context.delete(quote)
      }
    }
  }
}

extension DeleteQuoteInteractor {
  public struct Request: Sendable {
    public let quoteObjectIDs: [NSManagedObjectID]

    public init(quoteObjectIDs: [NSManagedObjectID]) {
      self.quoteObjectIDs = quoteObjectIDs
    }
    
    public init(quoteObjectID: NSManagedObjectID) {
      self.quoteObjectIDs = [quoteObjectID]
    }
  }
}