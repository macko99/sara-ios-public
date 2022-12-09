//
//  this class provides extension of local storage data type StoredUser, representation of data stored in device memory
//
//  Take a note of optional parameters
//
//  StoredUser+CoreDataProperties.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//
//

import Foundation
import CoreData


extension StoredUser {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoredUser> {
        return NSFetchRequest<StoredUser>(entityName: "StoredUser")
    }

    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var phone: String?
    @NSManaged public var id: String?
    @NSManaged public var color: String?

}

extension StoredUser : Identifiable {

}
