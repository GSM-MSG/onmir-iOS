import Foundation
import Combine
import Observation

@MainActor
@Observable
final class BookSearchViewModel {
  private(set) var books: [BookSearchRepresentation] = []
  private(set) var selectedBook: BookSearchRepresentation?
  
  private(set) var isLoading = false
  private(set) var currentPage = 0
  private(set) var hasMorePages = true
  private(set) var lastQuery = ""
  private let maxResultsPerPage = 20
  
  @ObservationIgnored
  private let googleBooksClient = GoogleBooksClient()
  
  var hasSelectedBook: Bool {
    return selectedBook != nil
  }
  
  func fetchBooks(query: String) async {
    if query != lastQuery {
      lastQuery = query
      currentPage = 0
      books = []
      hasMorePages = true
    }
    
    guard !isLoading && hasMorePages else { return }
    
    isLoading = true
    
    do {
      let startIndex = currentPage * maxResultsPerPage
      let response = try await googleBooksClient.searchBooks(
        query: query,
        startIndex: startIndex,
        maxResults: maxResultsPerPage
      )
      
      if let items = response.items, !items.isEmpty {
        let bookRepresentations = items.map { BookSearchRepresentation(from: $0) }
        
        await MainActor.run {
          if currentPage == 0 {
            self.books = bookRepresentations
          } else {
            self.books.append(contentsOf: bookRepresentations)
          }
          
          currentPage += 1
          hasMorePages = items.count == maxResultsPerPage && self.books.count < response.totalItems
        }
      } else {
        hasMorePages = false
      }
    } catch .cancelled {
      Logger.info("Book Fetch Cancelled")
    } catch {
      Logger.error(error)
    }
    
    isLoading = false
  }
  
  func loadMoreBooksIfNeeded(currentIndex: Int) {
    let thresholdIndex = books.count - 5
    if currentIndex >= thresholdIndex && !isLoading && hasMorePages {
      Task {
        await fetchBooks(query: lastQuery)
      }
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
