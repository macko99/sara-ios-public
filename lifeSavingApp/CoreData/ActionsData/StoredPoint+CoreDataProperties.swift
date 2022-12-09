//
//  this class provides extension of local storage data type StoredPoint
//
//  Take a note of optional parameters
//
//  StoredPoint+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//
//

import Foundation
import CoreData


extension StoredPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredPoint> {
        return NSFetchRequest<StoredPoint>(entityName: "StoredPoint")
    }

    @NSManaged public var blob: Data?
    @NSManaged public var descriptionText: String?
    @NSManaged public var id: Int16
    @NSManaged public var kind: Int16
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var timestamp: Int32
    @NSManaged public var type: String?
    @NSManaged public var uuid: String?
    @NSManaged public var userID: String?
    @NSManaged public var action: StoredAction?

}

extension StoredPoint : Identifiable {

}
