//
//  ReadingRecord+CoreDataProperties.swift
//  ONMIR
//
//  Created by 정윤서 on 6/23/25.
//
//

import Foundation
import CoreData


extension ReadingRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingRecord> {
        return NSFetchRequest<ReadingRecord>(entityName: "ReadingRecord")
    }

    @NSManaged public var id: String?
    @NSManaged public var read_date: Date?
    @NSManaged public var read_note: String?
    @NSManaged public var read_page: Int32
    @NSManaged public var read_time: Date?
    @NSManaged public var book: Book?

}

extension ReadingRecord : Identifiable {

}
