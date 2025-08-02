import Foundation
import Observation

@MainActor
@Observable
public final class BookRecordEditorViewModel {
  public enum EditMode: @unchecked Sendable {
    case create
    case edit(ReadingLogEntity)
  }

  public let book: BookEntity
  public let editMode: EditMode

  @ObservationIgnored
  private let contextManager: ContextManager
  
  @ObservationIgnored
  private let originalDate: Date
  @ObservationIgnored
  private let originalStartPage: Int
  @ObservationIgnored
  private let originalCurrentPage: Int
  @ObservationIgnored
  private let originalDuration: TimeInterval
  @ObservationIgnored
  private let originalNote: String
  
  public var date: Date = Date()
  public var startPage: Int = 0
  public var currentPage: Int
  public var totalPages: Int = 586
  
  public var duration: TimeInterval = 60 * 5
  
  public var note: String = ""
  
  public init(book: BookEntity, editMode: EditMode = .create, contextManager: ContextManager = .shared) {
    self.book = book
    self.editMode = editMode
    self.contextManager = contextManager
    self.totalPages = Int(book.pageCount)
    
    switch editMode {
    case .create:
      let initialDate = Date()
      let initialStartPage = 0
      let initialCurrentPage = 0
      let initialDuration = TimeInterval(60 * 5)
      let initialNote = ""
      
      self.date = initialDate
      self.startPage = initialStartPage
      self.currentPage = initialCurrentPage
      self.duration = initialDuration
      self.note = initialNote
      
      self.originalDate = initialDate
      self.originalStartPage = initialStartPage
      self.originalCurrentPage = initialCurrentPage
      self.originalDuration = initialDuration
      self.originalNote = initialNote
      
    case .edit(let readingLog):
      let initialDate = readingLog.date ?? Date()
      let initialStartPage = Int(readingLog.startPage)
      let initialCurrentPage = Int(readingLog.endPage)
      let initialDuration = readingLog.readingSeconds
      let initialNote = readingLog.note ?? ""
      
      self.date = initialDate
      self.startPage = initialStartPage
      self.currentPage = initialCurrentPage
      self.duration = initialDuration
      self.note = initialNote
      
      self.originalDate = initialDate
      self.originalStartPage = initialStartPage
      self.originalCurrentPage = initialCurrentPage
      self.originalDuration = initialDuration
      self.originalNote = initialNote
    }
  }
  
  public var hasChanges: Bool {
    return date != originalDate ||
           startPage != originalStartPage ||
           currentPage != originalCurrentPage ||
           abs(duration - originalDuration) > 1.0 ||
           note != originalNote
  }
  
  public func save() async {
    do {
      let date = self.date
      let startPage = self.startPage
      let currentPage = self.currentPage
      let duration = self.duration
      let note = self.note
      let book = self.book
      let editMode = self.editMode
      
      try await contextManager.performAndSave { context in
        let readingLog: ReadingLogEntity
        
        switch editMode {
        case .create:
          readingLog = ReadingLogEntity(context: context)
          let book = context.object(with: book.objectID) as? BookEntity
          assert(book != nil)
          readingLog.book = book

          context.insert(readingLog)
          
        case .edit(let existingLog):
          readingLog = existingLog
        }
        
        readingLog.date = date
        readingLog.startPage = Int64(startPage)
        readingLog.endPage = Int64(currentPage)
        readingLog.readingSeconds = duration
        readingLog.note = note.isEmpty ? nil : note
      }
    } catch {
      print("Failed to save reading record: \(error)")
    }
  }
}
