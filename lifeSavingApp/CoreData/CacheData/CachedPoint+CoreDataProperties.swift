//
//  CachedPoint+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/10/2021.
//
//

import Foundation
import CoreData


extension CachedPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CachedPoint> {
        return NSFetchRequest<CachedPoint>(entityName: "CachedPoint")
    }

    @NSManaged public var action: Int16
    @NSManaged public var longitude: Double
    @NSManaged public var uuid: String?
    @NSManaged public var type: String?
    @NSManaged public var blob: Data?
    @NSManaged public var timestamp: Int32
    @NSManaged public var latitude: Double
    @NSManaged public var name: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var kind: Int16

}

extension CachedPoint : Identifiable {

}
