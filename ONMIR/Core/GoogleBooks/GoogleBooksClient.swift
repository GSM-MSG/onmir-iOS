import Foundation

public struct GoogleBooksClient: Sendable {
  public enum GoogleBooksError: Error {
    case invalidURL
    case unexpectedResponse
    case decodingError(Error)
    case underlying(Error)
    case cancelled
  }
  
  public enum OrderByType: String, Sendable {
    case newest
    case relevance
  }

  private let session: URLSession
  private let baseURL = "https://www.googleapis.com/books/v1"

  public init(session: URLSession = .shared) {
    self.session = session
  }

  /// 책 검색
  /// - Parameters:
  ///   - query: 검색어
  ///   - maxResults: 최대 결과 수 (기본값: 20)
  /// - Returns: `BookSearchResponse`
  public func searchBooks(
    query: String,
    startIndex: Int,
    orderBy: OrderByType = .relevance,
    maxResults: Int = 20
  ) async throws(GoogleBooksError) -> BookSearchResponse {
    var components = URLComponents(string: "\(baseURL)/volumes")
    components?.queryItems = [
      URLQueryItem(name: "q", value: query),
      URLQueryItem(name: "startIndex", value: "\(startIndex)"),
      URLQueryItem(name: "orderBy", value: orderBy.rawValue),
      URLQueryItem(name: "maxResults", value: "\(maxResults)"),
    ]

    guard let url = components?.url else {
      throw GoogleBooksError.invalidURL
    }

    do {
      let (data, response) = try await session.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode)
      else {
        throw GoogleBooksError.unexpectedResponse
      }

      let decoder = JSONDecoder()
      return try decoder.decode(BookSearchResponse.self, from: data)
    } catch let decodingError as DecodingError {
      throw GoogleBooksError.decodingError(decodingError)
    } catch let urlError as URLError {
      if urlError.code == .cancelled {
        throw GoogleBooksError.cancelled
      } else {
        throw GoogleBooksError.underlying(urlError)
      }
    } catch {
      throw GoogleBooksError.underlying(error)
    }
  }
}

extension GoogleBooksClient {
  public struct BookSearchResponse: Decodable, Sendable {
    public let items: [BookItem]?
    public let totalItems: Int
    public let kind: String

    public struct BookItem: Decodable, Sendable {
      public var id: String
      public let volumeInfo: VolumeInfo
      public let saleInfo: SaleInfo?

      public struct VolumeInfo: Decodable, Sendable {
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
        public let industryIdentifiers: [IndustryIdentifier]?

        public struct IndustryIdentifier: Decodable, Sendable {
          public let type: String
          public let identifier: String
        }

        public struct ImageLinks: Decodable, Sendable {
          public let smallThumbnail: String?
          public let thumbnail: String?
          public let extraLarge: String?
        }
      }

      public struct SaleInfo: Decodable, Sendable {
        public let listPrice: Price?
        public let retailPrice: Price?
        public let buyLink: String?

        public struct Price: Decodable, Sendable {
          public let amount: Double?
          public let currencyCode: String?
        }
      }
    }
  }
}
