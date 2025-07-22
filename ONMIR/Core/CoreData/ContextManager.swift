@preconcurrency import CoreData
import os

public final class ContextManager: CoreDataStack, Sendable {
  private enum Constants: Sendable {
    static let appGroup = "group.msg.booktracker"
    static let cloudContainerIdentifier: String = "iCloud.msg.onmir"
    static let inMemoryStoreURL: URL = URL(fileURLWithPath: "/dev/null")
    static let databaseName: String = "OnmirModel"
  }

  private let modelName: String
  private let storeURL: URL
  private let persistentContainer: NSPersistentCloudKitContainer

  public var mainContext: NSManagedObjectContext {
    persistentContainer.viewContext
  }

  public static let shared: ContextManager = {
    ContextManager(
      modelName: Constants.databaseName,
      store: FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: Constants.appGroup
      )!
    )
  }()

  init(modelName: String, store storeURL: URL) {
    self.modelName = modelName
    self.storeURL = storeURL
    self.persistentContainer = Self.createPersistentContainer(
      storeURL: storeURL,
      modelName: modelName
    )

    mainContext.automaticallyMergesChangesFromParent = true
    mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
  }

  public func newDerivedContext() -> NSManagedObjectContext {
    let context = persistentContainer.newBackgroundContext()
    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    return context
  }
}

extension ContextManager {
  private static func createPersistentContainer(
    storeURL: URL,
    modelName: String
  ) -> NSPersistentCloudKitContainer {
    guard
      let modelFileURL = Bundle.main.url(
        forResource: modelName,
        withExtension: "momd"
      )
    else {
      fatalError("Can't find \(Constants.databaseName).momd")
    }

    guard
      let objectModel = NSManagedObjectModel(contentsOf: modelFileURL)
    else {
      fatalError(
        "Can't create object model named \(modelName) at \(modelFileURL)"
      )
    }

    guard
      let stagedMigrationFactory = StagedMigrationFactory(
        bundle: .main,
        momdURL: modelFileURL,
        logger: os.Logger.contextManager
      )
    else {
      fatalError("Can't create StagedMigrationFactory")
    }

    let baseURL =
      storeURL
      .appendingPathComponent("Onmir", isDirectory: true)
      .appendingPathComponent("CoreData", isDirectory: true)

    if !FileManager.default.fileExists(
      atPath: baseURL.path(percentEncoded: false)
    ) {
      do {
        try FileManager.default.createDirectory(
          at: baseURL,
          withIntermediateDirectories: true
        )
      } catch {
        os.Logger.contextManager.error("Can't create directory: \(error)")
      }
    }

    let sqliteURL =
      baseURL
      .appending(component: "ONMIR", directoryHint: .notDirectory)
      .appendingPathExtension("sqlite")

    os.Logger.contextManager.debug("\(sqliteURL)")
    let storeDescription = NSPersistentStoreDescription(url: sqliteURL)
    // storeDescription.url = Constants.inMemoryStoreURL
    storeDescription.type = NSSQLiteStoreType
    storeDescription.setOption(
      stagedMigrationFactory.create(),
      forKey: NSPersistentStoreStagedMigrationManagerOptionKey
    )
    storeDescription.shouldAddStoreAsynchronously = false

    storeDescription.cloudKitContainerOptions =
      NSPersistentCloudKitContainerOptions(
        containerIdentifier: Constants.cloudContainerIdentifier
      )
    storeDescription.setOption(
      true as NSNumber,
      forKey: NSPersistentHistoryTrackingKey
    )
    storeDescription.setOption(
      true as NSNumber,
      forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
    )

    let persistentContainer = NSPersistentCloudKitContainer(
      name: modelName,
      managedObjectModel: objectModel
    )
    persistentContainer.persistentStoreDescriptions = [storeDescription]

    persistentContainer.viewContext.automaticallyMergesChangesFromParent = true

    persistentContainer.loadPersistentStores { _, error in
      if let error {
        os.Logger.contextManager.error("\(error)")

        assertionFailure("Can't initialize Core Data stack")
      }
    }

    return persistentContainer
  }

  private static func storeURL() -> URL {
    guard
      let fileContainer = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: Constants.appGroup
      )
    else {
      fatalError()
    }
    return fileContainer
  }
}

private extension os.Logger {
  static let contextManager = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "", category: "ContextManager")
}
