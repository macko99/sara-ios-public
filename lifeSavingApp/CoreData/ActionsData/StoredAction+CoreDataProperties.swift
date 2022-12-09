//
//  this class provides extension of local storage data type StoredAction, representation of data stored in device memory as well as basic methods from system DAL api (so cool :))
//
//  Take a note of optional parameters
//
//  StoredAction+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//
//

import Foundation
import CoreData


extension StoredAction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredAction> {
        return NSFetchRequest<StoredAction>(entityName: "StoredAction")
    }

    @NSManaged public var descriptionText: String?
    @NSManaged public var id: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var radius: Double
    @NSManaged public var startTime: Int32
    @NSManaged public var areas: Set<StoredArea>?
    @NSManaged public var points: Set<StoredPoint>?

}

//Generated accessors for areas
extension StoredAction {

    @objc(addAreasObject:)
    @NSManaged public func addToAreas(_ value: StoredArea)

    @objc(removeAreasObject:)
    @NSManaged public func removeFromAreas(_ value: StoredArea)

    @objc(addAreas:)
    @NSManaged public func addToAreas(_ values: Set<StoredArea>)

    @objc(removeAreas:)
    @NSManaged public func removeFromAreas(_ values: Set<StoredArea>)

}

//Generated accessors for points
extension StoredAction {

    @objc(addPointsObject:)
    @NSManaged public func addToPoints(_ value: StoredPoint)

    @objc(removePointsObject:)
    @NSManaged public func removeFromPoints(_ value: StoredPoint)

    @objc(addPoints:)
    @NSManaged public func addToPoints(_ values: Set<StoredPoint>)

    @objc(removePoints:)
    @NSManaged public func removeFromPoints(_ values: Set<StoredPoint>)

}

extension StoredAction : Identifiable {

}
