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

  init(from bookItem: GoogleBooksClient.BookSearchResponse.BookItem) {
    self.id = bookItem.id
    self.title = bookItem.volumeInfo.title
    self.subtitle = bookItem.volumeInfo.subtitle
    self.authors = bookItem.volumeInfo.authors
    self.publisher = bookItem.volumeInfo.publisher
    self.publishedDate = bookItem.volumeInfo.publishedDate
    self.description = bookItem.volumeInfo.description

    if let thumbnailURLString = bookItem.volumeInfo.imageLinks?.thumbnail {
      let secureURL = thumbnailURLString.replacingOccurrences(
        of: "http://",
        with: "https://"
      )
      self.thumbnailURL = URL(string: secureURL)
    } else {
      self.thumbnailURL = nil
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func == (lhs: BookSearchRepresentation, rhs: BookSearchRepresentation) -> Bool {
    return lhs.id == rhs.id && lhs.title == rhs.title
      && lhs.subtitle == rhs.subtitle && lhs.authors == rhs.authors
      && lhs.publisher == rhs.publisher
      && lhs.publishedDate == rhs.publishedDate
      && lhs.description == rhs.description
  }
}
