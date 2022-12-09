//
//  Small class resposible for fetching other users data from server - used in points details view
//
//  UsersController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/06/2021.
//

import Foundation
import Combine

class UsersController: ObservableObject{
    
    //uses system defaults
    let defaults = UserDefaults.standard
    //DAL class for accessing users data in device memory
    let userDataController = UserDataController()
    let didChange = PassthroughSubject<UsersController,Never>()
    let willChange = PassthroughSubject<UsersController,Never>()
    //publically avaiable list
    @Published var loadingStateUsers = LoadingState.idle
    
    //in init we try to get users from device mem and save to to users list
    init(){
        userDataController.initalizeStack()
    }
    
    //function esposible for synchronization data in device memory
    func storeNewUsers(users: [User]) throws {
        //get all users in device memory
        let currentUsers: [User] = userDataController.getAllUsers()
        
        if !currentUsers.isEmpty{
            //it above list is not empty get ids of users and prepare todelete list
            let currentIds = currentUsers.map { $0.id }
            var toDelete = currentIds
            
            for user in users{
                let id = user.id
                //enumarate users provided to function and if we dont have such a user in dev mem -> save it
                if !currentIds.contains(id){
                    userDataController.storeUser(user: user)
                }
                //if such user exists -> udate his data
                else{
                    toDelete = toDelete.filter { $0 != id }
                    userDataController.updateUser(user: user) //MARK: not needed -> ok we let them change first/last name and color may change
                }
            }
            //delete users that are no longer in DB but still in dev mem
            for id in toDelete{
                userDataController.deleteUser(id: id)
            }
        }
        //if dev mem is empty save all new data to it
        else{
            for user in users{
                userDataController.storeUser(user: user)
            }
        }
    }
    
    //method fetching users data from server
    func fetchUsers(){
        self.loadingStateUsers = .loading
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/users")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.loadingStateUsers = .failed
                }
                return
            }
            
            if let data = data {
                //if we got data in repsonse we try to parde i form JSON and decode using custom UsersResponse data type
                if let decodedResponse = try? JSONDecoder().decode(UsersResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.loadingStateUsers = .loaded
                    }
                    do{
                        //try to store data in dev mem
                        try self.storeNewUsers(users: decodedResponse.users)
                    }
                    catch{}
                    return
                }
            }
            DispatchQueue.main.async {
                self.loadingStateUsers = .failed
            }
        }
        task.resume()
    }
    
}
