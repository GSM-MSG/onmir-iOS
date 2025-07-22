import CoreData
import Foundation
import OSLog

extension NSManagedObjectModelReference {
  fileprivate convenience init(in database: URL, modelName: String) {
    let modelURL = database.appending(component: "\(modelName).mom")
    guard let model = NSManagedObjectModel(contentsOf: modelURL) else { fatalError() }

    self.init(model: model, versionChecksum: model.versionChecksum)
  }
}

struct StagedMigrationFactory: Sendable {
  private let momdURL: URL
  private let logger: os.Logger

  init?(
    bundle: Bundle = .main,
    momdURL: URL,
    logger: os.Logger
  ) {
    self.momdURL = momdURL
    self.logger = logger
  }

  func create() -> NSStagedMigrationManager {
    let allStages: [NSCustomMigrationStage] = []

    return NSStagedMigrationManager(allStages)
  }
}
