import Foundation
import CoreData

struct ReadingBookInfo {
    let bookObjectID: NSManagedObjectID
    let title: String
    let author: String?
    let imageURL: URL?
    let currentPage: Int
    let totalPage: Int
}

@MainActor
final class HomeViewModel {
    var books: [ReadingBookInfo] = []
    private let createBookInteractor: CreateBookInteractor
    private let fetchBooksInteractor: FetchBooksInteractor

    init() {
        let contextManager = ContextManager.shared
        self.createBookInteractor = CreateBookInteractor(contextManager: contextManager)
        self.fetchBooksInteractor = FetchBooksInteractor(contextManager: contextManager)
    }

    func addBook(book: BookSearchRepresentation) async -> NSManagedObjectID? {
        let request = CreateBookInteractor.Request(
            originalBookID: book.id,
            title: book.title,
            author: book.authors?.joined(separator: ","),
            isbn: book.isbn,
            isbn13: book.isbn13,
            pageCount: book.pageCount,
            publishedDate: nil,
            publisher: book.publisher,
            rating: 0.0,
            source: .googleBooks,
            status: .toRead,
            coverImageURL: book.thumbnailURL
        )

        do {
            try await createBookInteractor(request: request)
            
            let context = ContextManager.shared.mainContext
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "originalBookID == %@", book.id)
            fetchRequest.fetchLimit = 1
            
            if let bookEntity = try? context.fetch(fetchRequest).first {
                let readingBook = ReadingBookInfo(
                    bookObjectID: bookEntity.objectID,
                    title: book.title,
                    author: book.authors?.joined(separator: ", "),
                    imageURL: book.thumbnailURL,
                    currentPage: 0,
                    totalPage: Int(book.pageCount)
                )
                books.append(readingBook)
                return bookEntity.objectID
            }
        } catch {
            Logger.error(error)
        }
        return nil
    }
    
    func loadBooks() async {
        do {
          let bookEntities = try await fetchBooksInteractor(request: .init(limit: 10))
            await MainActor.run {
                self.books = bookEntities.map { entity in
                    let currentPage = self.getCurrentPage(from: entity)
                    return ReadingBookInfo(
                        bookObjectID: entity.objectID,
                        title: entity.title ?? "Unknown Title",
                        author: entity.author,
                        imageURL: entity.coverImageURL,
                        currentPage: currentPage,
                        totalPage: Int(entity.pageCount)
                    )
                }
            }
        } catch {
            Logger.error(error)
            await MainActor.run {
                self.books = []
            }
        }
    }
    
    private func getCurrentPage(from entity: BookEntity) -> Int {
        guard let logs = entity.logs?.allObjects as? [ReadingLogEntity],
              !logs.isEmpty else {
            return 0
        }
        
        let sortedLogs = logs.sorted { log1, log2 in
            guard let date1 = log1.date, let date2 = log2.date else {
                return false
            }
            return date1 > date2
        }
        
        if let latestLog = sortedLogs.first {
            return Int(latestLog.endPage)
        }
        
        return 0
    }
    
    func refreshBooks() async {
        await loadBooks()
    }
}
