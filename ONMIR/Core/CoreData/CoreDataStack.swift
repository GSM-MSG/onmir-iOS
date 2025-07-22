@_exported import CoreData

public protocol CoreDataStack: Sendable {
  var mainContext: NSManagedObjectContext { get }

  func newDerivedContext() -> NSManagedObjectContext

  func performAndSaveLock<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T
  func performAndSave<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T

  func performAndSaveLock(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) throws
  func performAndSave(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) async throws

  func performQueryLock<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T
  func performQuery<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T
}

extension CoreDataStack {
  public func performAndSaveLock<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    let context = newDerivedContext()
    return try context.performAndWait {
      let result = try block(context)

      try context.save()
      return result
    }
  }

  public func performAndSave<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
    let context = newDerivedContext()
    return try await context.perform {
      let result = try block(context)

      try context.save()
      return result
    }
  }

  public func performAndSaveLock(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) throws {
    let context = newDerivedContext()
    try context.performAndWait {
      try block(context)

      try context.save()
    }
  }

  public func performAndSave(_ block: sending @escaping (NSManagedObjectContext) throws -> Void) async throws {
    let context = newDerivedContext()
    try await context.perform {
      try block(context)

      try context.save()
    }
  }

  public func performQueryLock<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) throws -> T {
    let context = newDerivedContext()
    return try context.performAndWait {
      try block(context)
    }
  }

  public func performQuery<T>(_ block: sending @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
    let context = newDerivedContext()
    return try await context.perform {
      try block(context)
    }
  }
}
