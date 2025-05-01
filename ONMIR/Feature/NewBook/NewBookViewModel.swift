import Foundation
import Combine
import Observation

@MainActor
@Observable
final class NewBookViewModel {
  private(set) var books: [BookSearchRepresentation] = []
  private(set) var selectedBook: BookSearchRepresentation?
  
  @ObservationIgnored
  private let googleBooksClient = GoogleBooksClient()
  
  var hasSelectedBook: Bool {
    return selectedBook != nil
  }
  
  func fetchBooks(query: String) async {
    do {
      let response = try await googleBooksClient.searchBooks(
        query: query,
        startIndex: 0
      )
      
      if let items = response.items {
        let bookRepresentations = items.map { BookSearchRepresentation(from: $0) }
        
        await MainActor.run {
          self.books = bookRepresentations
        }
      }
    } catch {
      Logger.error("Error fetching books: \(error)")
    }
  }
  
  func toggleBookSelection(book: BookSearchRepresentation) {
    if let currentSelectedBook = selectedBook, currentSelectedBook.id == book.id {
      selectedBook = nil
    } else {
      selectedBook = book
    }
  }
  
  func clearSelection() {
    selectedBook = nil
  }
} 
