//
//  this class provides extension of local storage data type StoredLocation, representation of data stored in device memory
//
//  StoredLocation+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 28/04/2021.
//
//

import Foundation
import CoreData


extension StoredLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredLocation> {
        return NSFetchRequest<StoredLocation>(entityName: "StoredLocation")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var altitude: Double
    @NSManaged public var speed: Double
    @NSManaged public var speedAcc: Double
    @NSManaged public var horizontalAcc: Double
    @NSManaged public var verticalAcc: Double
    @NSManaged public var course: Double
    @NSManaged public var courseAcc: Double
    @NSManaged public var timestamp: Int32

}

extension StoredLocation : Identifiable {

}
