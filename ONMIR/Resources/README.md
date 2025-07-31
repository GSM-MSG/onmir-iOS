#  OnmirModel V1

## Entities

### BookEntity
- author: String
- coverImageURL: URI
- isbn: String
- isbn13: String
- originalBookID: String
- source: BookSourceTypeKind
- pageCount: Int64
- publishedDate: Date
- publisher: String
- rating: Double
- status: BookStatusTypeKind
- title: String

Relationships:
- logs: [ReadingLogEntity] - Cascade
- quotes: [QuoteEntity] - Cascade

### QuoteEntity
- content: String
- page: Int

Relationships:
- book: BookEntity

### ReadingLogEntity
- startPage: Int64
- endPage: Int64
- note: String
- readingSeconds: Double
- date: Date

Relationships:
- book: BookEntity
