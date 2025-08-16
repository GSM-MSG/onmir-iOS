import Foundation
import Observation

@MainActor
@Observable
public final class QuoteEditorViewModel {
  public enum EditMode: @unchecked Sendable {
    case create
    case edit(QuoteEntity)
  }

  public let book: BookEntity
  public let editMode: EditMode

  @ObservationIgnored
  private let contextManager: ContextManager
  
  @ObservationIgnored
  private let originalContent: String
  @ObservationIgnored
  private let originalPage: Int
  
  public var content: String = ""
  public var page: Int = 1
  public var totalPages: Int = 0
  
  public init(book: BookEntity, editMode: EditMode = .create, contextManager: ContextManager = .shared) {
    self.book = book
    self.editMode = editMode
    self.contextManager = contextManager
    self.totalPages = Int(book.pageCount)
    
    let initialContent: String
    let initialPage: Int

    switch editMode {
    case .create:
      initialContent = ""
      initialPage = 1

    case .edit(let quote):
      initialContent = quote.content ?? ""
      initialPage = Int(quote.page)
    }

    self.content = initialContent
    self.page = initialPage

    self.originalContent = initialContent
    self.originalPage = initialPage
  }
  
  public var hasChanges: Bool {
    return content != originalContent ||
           page != originalPage
  }
  
  public var isValid: Bool {
    return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           page >= 1 &&
           page <= totalPages
  }
  
  public func save() async throws {
    let content = self.content.trimmingCharacters(in: .whitespacesAndNewlines)
    let page = self.page
    let book = self.book
    let editMode = self.editMode
    
    switch editMode {
    case .create:
      let createInteractor = CreateQuoteInteractor(contextManager: contextManager)
      let request = CreateQuoteInteractor.Request(
        content: content,
        page: Int64(page),
        bookObjectID: book.objectID
      )
      try await createInteractor(request: request)
      
    case .edit(let existingQuote):
      let updateInteractor = UpdateQuoteInteractor(contextManager: contextManager)
      let request = UpdateQuoteInteractor.Request(
        quoteObjectID: existingQuote.objectID,
        content: content,
        page: Int64(page)
      )
      try await updateInteractor(request: request)
    }
  }
}