import Foundation

struct ReadingBookInfo {
    let imageURL: URL?
    let currentPage: Int
    let totalPage: Int
}

final class HomeViewModel {
    var books: [ReadingBookInfo] = []
}
