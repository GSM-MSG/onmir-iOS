import Foundation
import UIKit

public struct ManualBookRepresentation: Sendable, Hashable, Identifiable {
  public let id: String
  public let title: String?
  public let author: String?
  public let publisher: String?
  public let publishedDate: String?
  public let description: String?
  public let coverImage: UIImage?
  public let isbn: String?
  public let isbn13: String?
  public let pageCount: Int64
  public let readingStatus: BookStatusType
  
  public init(
    title: String? = nil,
    author: String? = nil,
    publisher: String? = nil,
    publishedDate: String? = nil,
    description: String? = nil,
    coverImage: UIImage? = nil,
    isbn: String? = nil,
    isbn13: String? = nil,
    pageCount: Int64 = 0,
    readingStatus: BookStatusType = .toRead
  ) {
    self.id = UUID().uuidString
    self.title = title
    self.author = author
    self.publisher = publisher
    self.publishedDate = publishedDate
    self.description = description
    self.coverImage = coverImage
    self.isbn = isbn
    self.isbn13 = isbn13
    self.pageCount = pageCount
    self.readingStatus = readingStatus
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
  
  public static func == (lhs: ManualBookRepresentation, rhs: ManualBookRepresentation) -> Bool {
    return lhs.id == rhs.id
  }
}