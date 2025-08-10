import Foundation

public struct BookRepresentation: Sendable, Hashable {
  public let originalBookID: String?
  public let title: String
  public let author: String?
  public let isbn: String?
  public let isbn13: String?
  public let pageCount: Int64
  public let publishedDate: Date?
  public let publisher: String?
  public let rating: Double
  public let source: BookSourceType?
  public let status: BookStatusType?
  public let coverImageURL: URL?

  public init(
    originalBookID: String,
    title: String,
    author: String? = nil,
    isbn: String? = nil,
    isbn13: String? = nil,
    pageCount: Int64 = 0,
    publishedDate: Date? = nil,
    publisher: String? = nil,
    rating: Double = 0.0,
    source: BookSourceType = .googleBooks,
    status: BookStatusType? = nil,
    coverImageURL: URL? = nil
  ) {
    self.originalBookID = originalBookID
    self.title = title
    self.author = author
    self.isbn = isbn
    self.isbn13 = isbn13
    self.pageCount = pageCount
    self.publishedDate = publishedDate
    self.publisher = publisher
    self.rating = rating
    self.source = source
    self.status = status
    self.coverImageURL = coverImageURL
  }
}

extension BookRepresentation {
  public init(from bookEntity: BookEntity) {
    self.originalBookID = bookEntity.originalBookID
    self.title = bookEntity.title ?? ""
    self.author = bookEntity.author
    self.isbn = bookEntity.isbn
    self.isbn13 = bookEntity.isbn13
    self.pageCount = bookEntity.pageCount
    self.publishedDate = bookEntity.publishedDate
    self.publisher = bookEntity.publisher
    self.rating = bookEntity.rating
    self.source = bookEntity.source?.sourceType
    self.status = bookEntity.status?.status
    self.coverImageURL = bookEntity.coverImageURL
  }
}
