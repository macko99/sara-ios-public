//
//  this class provides extension of local storage data type StoredArea, representation of data stored in device memory as well as basic methods from system DAL api (so cool :))
//
//  Take a note of optional parameters
//
//  StoredArea+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//
//

import Foundation
import CoreData


extension StoredArea {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredArea> {
        return NSFetchRequest<StoredArea>(entityName: "StoredArea")
    }

    @NSManaged public var id: Int16
    @NSManaged public var name: String?
    @NSManaged public var action: StoredAction?
    @NSManaged public var coordinates: Set<StoredCoordinate>?

}

//Generated accessors for coordinates
extension StoredArea {

    @objc(addCoordinatesObject:)
    @NSManaged public func addToCoordinates(_ value: StoredCoordinate)

    @objc(removeCoordinatesObject:)
    @NSManaged public func removeFromCoordinates(_ value: StoredCoordinate)

    @objc(addCoordinates:)
    @NSManaged public func addToCoordinates(_ values: Set<StoredCoordinate>)

    @objc(removeCoordinates:)
    @NSManaged public func removeFromCoordinates(_ values: Set<StoredCoordinate>)

}

extension StoredArea : Identifiable {

}
