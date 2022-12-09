//
//  Controller used by Profile View to update current user data (such as password username etc...)
//
//  UserDataPatchController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 13/06/2021.
//

import Foundation
import Combine

class UserDataPatchController: ObservableObject{
    
    let defaults = UserDefaults.standard
    let didChange = PassthroughSubject<UserDataPatchController,Never>()
    let willChange = PassthroughSubject<UserDataPatchController,Never>()
    
    init(){
    }
    
    //custom return enum UpdateResult
    func updateUserName(newUsername: String) -> UpdateResult{
        let sem = DispatchSemaphore.init(value: 0)
        var result: UpdateResult = .waiting
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/users/update/username")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: ["username": newUsername],
            options: []
        )
        request.httpMethod = "PATCH"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { sem.signal() }
            
            if error != nil {
                result = .failed
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: String]
                //if we got new username in response than it is changes successfully
                if let username = json?["username"] {
                    DispatchQueue.main.async {
                        self.defaults.set(username, forKey: "username")
                    }
                }
                //in addiction we have to get new JWT token because each token is linkes with username -> we have to update it in system defaults so every controller now can use it and authenticate reqests with success
                if let receivedToken = json?["access_token"] {
                    DispatchQueue.main.async {
                        self.defaults.set("Bearer \(receivedToken)", forKey: "authToken")
                    }
                }
                if let receivedTokenR = json?["refresh_token"] {
                    DispatchQueue.main.async {
                        self.defaults.set("Bearer \(receivedTokenR)", forKey: "authTokenRefresh")
                    }
                }
                //if the entered username is already taken!
                if let msg = json?["msg"] {
                    if (msg == "username taken"){
                        result = .usernameTaken
                        return
                    }
                }
                result = .success
                return
            } catch {
                result = .failed
                return
            }
        }
        task.resume()
        
        sem.wait()
        return result
    }
    
    func updateNames(newFirstName: String, newLastName: String) -> UpdateResult{
        let sem = DispatchSemaphore.init(value: 0)
        var result: UpdateResult = .waiting
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/users/update/names")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: ["first_name": newFirstName,
                             "last_name": newLastName],
            options: []
        )
        request.httpMethod = "PATCH"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { sem.signal() }
            
            if error != nil {
                result = .failed
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: String]
                //if we got new first name in response than it is changes successfully
                if let firstName = json?["first_name"] {
                    DispatchQueue.main.async {
                        self.defaults.set(firstName, forKey: "firstName")
                    }
                }
                if let lastName = json?["last_name"] {
                    DispatchQueue.main.async {
                        self.defaults.set(lastName, forKey: "lastName")
                    }
                }
                result = .success
                return
            } catch {
                result = .failed
                return
            }
        }
        task.resume()
        
        sem.wait()
        return result
    }
    
    func updatePassword(newPasswd: String) -> UpdateResult{
        let sem = DispatchSemaphore.init(value: 0)
        var result: UpdateResult = .waiting
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/users/update/password")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: ["password": newPasswd],
            options: []
        )
        request.httpMethod = "PATCH"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { sem.signal() }
            
            if error != nil {
                result = .failed
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: String]
                if let msg = json?["msg"] {
                    if (msg == "password changed"){
                        result = .success
                        return
                    }
                }
            } catch {
                result = .failed
                return
            }
        }
        task.resume()
        
        sem.wait()
        return result
    }
    
}
