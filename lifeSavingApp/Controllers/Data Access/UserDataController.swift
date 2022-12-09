//
//  DAL class for accessing users data in device memory
//
//  UserDataController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//

import Foundation
import CoreData

class UserDataController {
    
    let persistentContainer = NSPersistentContainer(name: "UsersData")
    
    func initalizeStack() {
        self.persistentContainer.loadPersistentStores { description, error in
            
            if error != nil {
                return
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    //saving user data delivered as StoredUser object to dev mem
    private func storeUser(user: StoredUser) throws {
        self.context.insert(user)
        try self.context.save()
    }
    
    //saving user data delivered as User object to dev mem
    func storeUser(user: User) {
        context.performAndWait{
            let newUser = StoredUser(context: self.context)
            newUser.firstName = user.firstName
            newUser.lastName = user.lastName
            newUser.id = user.id
            newUser.phone = user.phone
            newUser.color = user.color
            do{
                try self.storeUser(user: newUser)
            } catch{}
        }
    }
    
    func updateUser(user: User) {
        let request = NSFetchRequest<StoredUser>(entityName: "StoredUser")
        request.predicate = NSPredicate(format: "id == %@", user.id)
        
        context.performAndWait{
            do{
                let users = try self.context.fetch(request)
                if(users.isEmpty){
                    return
                }
                let toUpdateUser = users[0]
                toUpdateUser.firstName = user.firstName
                toUpdateUser.lastName = user.lastName
                toUpdateUser.color = user.color
                toUpdateUser.phone = user.phone
                
                try self.context.save()
            }
            catch {}
        }
    }
    
    private func getAllUsers() throws -> [StoredUser] {
        return try self.context.fetch(StoredUser.fetchRequest() as NSFetchRequest<StoredUser>)
    }
    
    func getAllUsers() -> [User] {
        var users = [User]()
        
        context.performAndWait{
            do{
                let storedUsers: [StoredUser] = try getAllUsers()
                users = storedUsers.map { $0.toUser }
            } catch{}
        }
        return users
    }
    
    func getAllAvatars() -> [String : Avatar] {
        var avatars = [String : Avatar]()
        
        context.performAndWait{
            do{
                let storedUsers: [StoredUser] = try getAllUsers()
                for storedUser in storedUsers {
                    avatars[storedUser.id!] = getAvatar(firstName: storedUser.firstName!,
                                                        lastName: storedUser.lastName!,
                                                        phone: storedUser.phone!,
                                                        color: storedUser.color!)
                }
            } catch{}
        }
        return avatars
    }
    
    private func getAvatar(firstName: String, lastName: String, phone: String, color: String) -> Avatar{
        if(firstName != "-") {
            if(lastName != "-") {
                return Avatar(color: color, avatar: firstName + " " + lastName.prefix(1))
            }
            return Avatar(color: color, avatar: firstName)
        }
        return Avatar(color: color, avatar: phone)
    }
    
    func deleteUser (id: String) {
        context.performAndWait{
            do{
                let user: StoredUser? = try getUser(id: id)
                
                self.context.delete(user!)
                try self.context.save()
            } catch{}
        }
    }
    
    private func getUser (id: String) throws -> StoredUser? {
        let request = NSFetchRequest<StoredUser>(entityName: "StoredUser")
        request.predicate = NSPredicate(format: "id == %@", id)
        
        let user = try self.context.fetch(request)
        if user.isEmpty{
            return nil
        }
        return user[0]
    }
    
    func getUser (id: String) -> User {
        var resultUser = User.dummyUser
        
        context.performAndWait{
            do{
                let user: StoredUser? = try getUser(id: id)
                resultUser = user!.toUser
            } catch{}
        }
        
        return resultUser
    }
    
    func deleteAllUsers() {
        let fetchRequest = StoredUser.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        context.performAndWait{
            do{
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch{}
        }
    }
    
}
