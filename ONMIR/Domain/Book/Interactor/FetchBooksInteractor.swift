import CoreData
import Foundation

public struct FetchBooksInteractor: Sendable {
  private let contextManager: any CoreDataStack

  public init(contextManager: any CoreDataStack = ContextManager.shared) {
    self.contextManager = contextManager
  }

  public func callAsFunction(request: Request = Request()) async throws -> [BookEntity] {
    return try await contextManager.performQuery { @Sendable context in
      let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
      
      var predicates: [NSPredicate] = []
      
      if let status = request.status {
        let statusPredicate = NSPredicate(format: "status.status == %@", status.rawValue)
        predicates.append(statusPredicate)
      }
      
      if !predicates.isEmpty {
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
      }
      
      if let limit = request.limit {
        fetchRequest.fetchLimit = limit
      }
      
      return try context.fetch(fetchRequest)
    }
  }
}

extension FetchBooksInteractor {
  public struct Request: Sendable {
    public let status: BookStatusType?
    public let limit: Int?

    public init(
      status: BookStatusType? = nil,
      limit: Int? = nil
    ) {
      self.status = status
      self.limit = limit
    }
  }
}
