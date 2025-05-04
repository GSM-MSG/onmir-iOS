import Foundation
import Observation

@MainActor
@Observable
public final class NewBookRecordViewModel {
  public let book: BookRepresentation
  
  public var currentPage: Int
  public var totalPages: Int = 586
  
  public var duration: TimeInterval = 60 * 5
  
  public var note: String = ""
  
  public init(book: BookRepresentation) {
    self.book = book
    self.currentPage = 0
  }
  
  public init(book: BookRepresentation, currentPage: Int) {
    self.book = book
    self.currentPage = currentPage
  }
  
  public func save() async {
    
  }
}
