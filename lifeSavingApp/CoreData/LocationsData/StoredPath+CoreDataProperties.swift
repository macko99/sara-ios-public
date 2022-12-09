//
//  this class provides extension of local storage data type StoredPath, representation of data stored in device memory
//
//  StoredPath+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 30/05/2021.
//
//

import Foundation
import CoreData


extension StoredPath {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredPath> {
        return NSFetchRequest<StoredPath>(entityName: "StoredPath")
    }

    @NSManaged public var longitude: Double
    @NSManaged public var latitude: Double
    @NSManaged public var timestamp: Int32
    @NSManaged public var action: Int32

}

extension StoredPath : Identifiable {

}
