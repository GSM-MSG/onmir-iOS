//
//  Book+CoreDataProperties.swift
//  ONMIR
//
//  Created by 정윤서 on 6/23/25.
//
//

import Foundation
import CoreData


extension Book {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var author: String
    @NSManaged public var book_cover_url: String
    @NSManaged public var id: Int16
    @NSManaged public var quotes: [String]
    @NSManaged public var rating: Double
    @NSManaged private var read_type: String
    @NSManaged public var title: String
    @NSManaged public var total_read_time: Date?
    @NSManaged public var readingRecord: NSSet?

    public var readType: ReadType {
        get {
            return ReadType(rawValue: read_type)!
        }
        set {
            read_type = newValue.rawValue
        }
    }

}

// MARK: Generated accessors for readingRecord
extension Book {

    @objc(addReadingRecordObject:)
    @NSManaged public func addToReadingRecord(_ value: String)

    @objc(removeReadingRecordObject:)
    @NSManaged public func removeFromReadingRecord(_ value: String)

    @objc(addReadingRecord:)
    @NSManaged public func addToReadingRecord(_ values: NSSet)

    @objc(removeReadingRecord:)
    @NSManaged public func removeFromReadingRecord(_ values: NSSet)

}

extension Book : Identifiable {

}
