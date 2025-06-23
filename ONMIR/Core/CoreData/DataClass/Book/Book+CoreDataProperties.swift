//
//  Book+CoreDataProperties.swift
//  ONMIR
//
//  Created by 정윤서 on 5/18/25.
//
//

import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var author: String
    @NSManaged public var book_cover_url: URL
    @NSManaged public var id: String
    @NSManaged public var quotes: [String]
    @NSManaged public var rating: Double
    @NSManaged fileprivate var read_type: String
    @NSManaged public var title: String
    @NSManaged public var total_read_time: Date
    @NSManaged public var readingRecord: NSSet?

}

// MARK: Generated accessors for readingRecord
extension Book {

    @objc(addReadingRecordObject:)
    @NSManaged public func addToReadingRecord(_ value: ReadingRecord)

    @objc(removeReadingRecordObject:)
    @NSManaged public func removeFromReadingRecord(_ value: ReadingRecord)

    @objc(addReadingRecord:)
    @NSManaged public func addToReadingRecord(_ values: NSSet)

    @objc(removeReadingRecord:)
    @NSManaged public func removeFromReadingRecord(_ values: NSSet)

    var readType: ReadType {
        get {
            return ReadType(rawValue: self.read_type) ?? .toRead
        } set {
            read_type = newValue.rawValue
        }
    }
}

extension Book : Identifiable {

}
