//
//  this class provides extension of local storage data type StoredCoordinate
//
//  Take a note of optional parameters
//
//  StoredCoordinate+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//
//

import Foundation
import CoreData


extension StoredCoordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredCoordinate> {
        return NSFetchRequest<StoredCoordinate>(entityName: "StoredCoordinate")
    }

    @NSManaged public var id: Int16
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var order: Int16
    @NSManaged public var area: StoredArea?

}

extension StoredCoordinate : Identifiable {

}
