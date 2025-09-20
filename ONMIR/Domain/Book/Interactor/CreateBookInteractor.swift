import CoreData
import Foundation
import UIKit

public struct CreateBookInteractor: Sendable {
  private let contextManager: any CoreDataStack

  public init(contextManager: any CoreDataStack = ContextManager.shared) {
    self.contextManager = contextManager
  }

  public func callAsFunction(request: Request) async throws {
    try await contextManager.performAndSave { @Sendable context in
      let bookEntity = BookEntity(context: context)
      bookEntity.originalBookID = request.originalBookID
      bookEntity.title = request.title
      bookEntity.author = request.author
      bookEntity.isbn = request.isbn
      bookEntity.isbn13 = request.isbn13
      bookEntity.pageCount = request.pageCount
      bookEntity.publishedDate = request.publishedDate
      bookEntity.publisher = request.publisher
      bookEntity.rating = request.rating
      bookEntity.source = request.source.map {
        BookSourceTypeKind(sourceType: $0)
      }
      bookEntity.status = request.status.map { BookStatusTypeKind(status: $0) }
      // Handle cover image source
      if let coverImageSource = request.coverImageSource {
        switch coverImageSource {
        case .url(let url):
          bookEntity.coverImageURL = url
        case .data(let data):
          let coverImageEntity = CoverImageDataEntity(context: context)
          coverImageEntity.data = data
          bookEntity.coverImageData = coverImageEntity
        }
      }

      context.insert(bookEntity)
    }
  }
}

extension CreateBookInteractor {
  public struct Request: Sendable {
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
    public let coverImageSource: CoverImageSource?

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
      coverImageSource: CoverImageSource? = nil
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
      self.coverImageSource = coverImageSource
    }
  }
}
