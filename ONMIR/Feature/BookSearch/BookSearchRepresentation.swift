import Foundation

public struct BookSearchRepresentation: Sendable, Hashable {
  public let id: String
  public let title: String
  public let subtitle: String?
  public let authors: [String]?
  public let publisher: String?
  public let publishedDate: String?
  public let description: String?
  public let thumbnailURL: URL?
  public let isbn: String?
  public let isbn13: String?
  public let pageCount: Int64

  init(from bookItem: GoogleBooksClient.BookSearchResponse.BookItem) {
    self.id = bookItem.id
    self.title = bookItem.volumeInfo.title
    self.subtitle = bookItem.volumeInfo.subtitle
    self.authors = bookItem.volumeInfo.authors
    self.publisher = bookItem.volumeInfo.publisher
    self.description = bookItem.volumeInfo.description
    self.pageCount = Int64(bookItem.volumeInfo.pageCount ?? 0)
    #warning("TODO: 연도만 오는 경우에 대한 처리 필요")
    self.publishedDate = bookItem.volumeInfo.publishedDate

    var isbn10: String?
    var isbn13: String?
    if let identifiers = bookItem.volumeInfo.industryIdentifiers {
      for identifier in identifiers {
        if identifier.type == "ISBN_10" {
          isbn10 = identifier.identifier
        } else if identifier.type == "ISBN_13" {
          isbn13 = identifier.identifier
        }
      }
    }
    self.isbn = isbn10
    self.isbn13 = isbn13

    if let thumbnailURLString = bookItem.volumeInfo.imageLinks?.extraLarge ?? bookItem.volumeInfo.imageLinks?.thumbnail {
      let secureURL = thumbnailURLString.replacingOccurrences(
        of: "http://",
        with: "https://"
      )
      if let baseURL = URL(string: secureURL) {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems?.append(URLQueryItem(name: "fife", value: "w400-h600"))
        self.thumbnailURL = urlComponents?.url ?? baseURL
      } else {
        self.thumbnailURL = nil
      }
    } else {
      self.thumbnailURL = nil
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: BookSearchRepresentation, rhs: BookSearchRepresentation) -> Bool {
    return lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle && lhs.authors == rhs.authors
      && lhs.publisher == rhs.publisher
      && lhs.publishedDate == rhs.publishedDate
      && lhs.description == rhs.description
  }
}
