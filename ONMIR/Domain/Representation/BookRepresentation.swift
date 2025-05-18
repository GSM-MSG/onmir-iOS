import Foundation

public struct BookRepresentation: Sendable, Hashable {
  public let id: String
  public let volumeInfo: VolumeInfo
  public let saleInfo: SaleInfo?

  public init(
    id: String,
    volumeInfo: VolumeInfo,
    saleInfo: SaleInfo?
  ) {
    self.id = id
    self.volumeInfo = volumeInfo
    self.saleInfo = saleInfo
  }

  public struct VolumeInfo: Sendable, Hashable {
    public let title: String
    public let subtitle: String?
    public let authors: [String]?
    public let publisher: String?
    public let publishedDate: String?
    public let description: String?
    public let pageCount: Int?
    public let categories: [String]?
    public let language: String?
    public let imageLinks: ImageLinks?

    public init(
      title: String,
      subtitle: String?,
      authors: [String]?,
      publisher: String?,
      publishedDate: String?,
      description: String?,
      pageCount: Int?,
      categories: [String]?,
      language: String?,
      imageLinks: ImageLinks?
    ) {
      self.title = title
      self.subtitle = subtitle
      self.authors = authors
      self.publisher = publisher
      self.publishedDate = publishedDate
      self.description = description
      self.pageCount = pageCount
      self.categories = categories
      self.language = language
      self.imageLinks = imageLinks
    }

    public struct ImageLinks: Sendable, Hashable {
      public let smallThumbnail: String?
      public let thumbnail: String?

      public init(smallThumbnail: String?, thumbnail: String?) {
        self.smallThumbnail = smallThumbnail
        self.thumbnail = thumbnail
      }
    }
  }

  public struct SaleInfo: Sendable, Hashable {
    public let listPrice: Price?
    public let retailPrice: Price?
    public let buyLink: String?

    public init(listPrice: Price?, retailPrice: Price?, buyLink: String?) {
      self.listPrice = listPrice
      self.retailPrice = retailPrice
      self.buyLink = buyLink
    }

    public struct Price: Sendable, Hashable {
      public let amount: Double?
      public let currencyCode: String?

      public init(amount: Double?, currencyCode: String?) {
        self.amount = amount
        self.currencyCode = currencyCode
      }
    }
  }
}
