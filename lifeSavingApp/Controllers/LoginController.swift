//
//  login controller is responsible for login, logout, checking if url/ip is in corrent form, obtaining user token, checking if token is still valid and initial fetching of user data
//  so sending http request and setting system variables regarding user session is all done here
//
//  LoginController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 02/05/2021.
//

extension NSNotification.Name {
    static let didLogOut = Notification.Name("didLogOut")
}

import Foundation
import Combine
import SwiftUI

//this calss is observable
class LoginController: ObservableObject {
    
    //using defaults to store same user info
    let defaults = UserDefaults.standard
    let didChange = PassthroughSubject<LoginController,Never>()
    let willChange = PassthroughSubject<LoginController,Never>()
    
    //elements available on observable object of this class
    @Published var ipAddr = "none"
    //defualt push interval in sec. Used as interval of pushing gps data back to server
    @Published var pushInterval = 60 //in sec
    @Published var observationWidth = 30 //in meters
    @Published var isLoggedin = false
    @Published var autoLogout = false
    //using enum LoadingState - used for shoing user state of sending request -> loading, idle, faild.....etc
    @Published var loadingUserData = LoadingState.idle
    
    @Published var showingChangePasswordAlert = false
    @Published var experimentalFeatures = false
    
    //default return code from http request - means nothing
    var returnCode = -1
    
    //in init process we try to read values of system defualts in case app has been used before
    init(){
        self.isLoggedin = defaults.bool(forKey: "loggedIn")
        
        ipAddr = defaults.string(forKey: "ipAddress") ?? "none"
        
        let recentPushInterval  = defaults.integer(forKey: "pushInterval")
        pushInterval = recentPushInterval == 0 ? 60 : recentPushInterval
        if (recentPushInterval == 0){
            defaults.set(pushInterval, forKey: "pushInterval")
        }
        
        let recentObservationWidth  = defaults.integer(forKey: "observationWidth")
        observationWidth = recentObservationWidth == 0 ? 30 : recentObservationWidth
        if (recentObservationWidth == 0){
            defaults.set(observationWidth, forKey: "observationWidth")
        }
        
        experimentalFeatures = defaults.bool(forKey: "experimentalFeatures")
    }
    
    //method is handling effent of login request -> set proper system defaults and calling method to fetch user data from server
    func login(username: String, password: String, usingCode: Bool) -> Bool{
        let res = getLoginToken(username: username, password: password, usingCode: usingCode)
        if (res != nil){
            defaults.set(username, forKey: "username")
            defaults.set("Bearer \(res!)", forKey: "authToken")
            getUserData()
            DispatchQueue.main.async {
                if(usingCode){
                    self.showingChangePasswordAlert = true
                }
                self.isLoggedin = true
            }
            defaults.set(true, forKey: "loggedIn")
            if (myToken != ""){
                defaults.set(myToken, forKey: "apnToken")
                uploadApnDeviceToken()
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didLogOut, object: nil)
            }
            DispatchQueue.main.resume()
            return true
        }
        return false
    }
    
    //methid is clearing system defaults and revoking token on server
    func logout() {
        revokeApnDeviceToken()
        revokeToken()
        defaults.set(false, forKey: "loggedIn")
        defaults.set("none", forKey: "authToken")
        defaults.set("none", forKey: "authTokenRefresh")
        defaults.set(false, forKey: "actionIsSet")
        defaults.set(false, forKey: "pushInterval")
        defaults.set(false, forKey: "observationWidth")
        defaults.set(false, forKey: "GPSisActive")
        defaults.set("none", forKey: "uuid")
        defaults.set("none", forKey: "apnToken")
        
        defaults.set("please refresh", forKey: "username")
        defaults.set("please refresh", forKey: "firstName")
        defaults.set("please refresh", forKey: "lastName")
        defaults.set("please refresh", forKey: "phone")
        defaults.set("-", forKey: "connectionTime")
        defaults.set("none", forKey: "oneTimeUser")
        
        defaults.set(false, forKey: "experimentalFeatures")
        
        self.isLoggedin = false
    }
    
    //small utility to check if url is openable
    func verifyUrl (urlString: String?) -> Bool {
        if let urlString = urlString {
            if let url = NSURL(string: urlString) {
                
                return UIApplication.shared.canOpenURL(url as URL)
            }
        }
        return false
    }
    
    //small utility to verify if provided string van be ip addr or corretn url
    func validateIpAddress(ipToValidate: String, portToValidate: String) -> Bool {
        if !portToValidate.isInt || Int(portToValidate)! > 65535 || Int(portToValidate)! < 0{
            return false
        }
        
        var sin = sockaddr_in()
        var sin6 = sockaddr_in6()
        
        if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
            return true
        }
        else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
            return true
        }
        return verifyUrl(urlString: "http://" + ipToValidate) ? true : false
    }
    
    //if user provided corrent ip/url we memorize it in controller to later be used in all http requests
    func setIpAddress(newIP: String, newPort: String, newScheme: Bool){
        let scheme = newScheme ? "https://" : "http://"
        let newServerAddress = newPort != "80" ?
        scheme + newIP + ":" + newPort :
        scheme + newIP
        
        defaults.set(newServerAddress, forKey: "ipAddress")
        self.ipAddr = newServerAddress
    }
    
    //actual login reqest handler
    func getLoginToken(username: String, password: String, usingCode: Bool) -> String?{
        var dataReceived: String?
        //semaphore used to tell app to wait until request response
        let sem = DispatchSemaphore.init(value: 0)
        
        //preparing request data
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        
        //preparing request url and object
        let url = usingCode ? URL(string: ipAddr + "/login/code")! : URL(string: ipAddr + "/login")!
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 //MARK: timeoutIntervalForRequest or login
        let session = URLSession(configuration: configuration)
        
        //sending request
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { sem.signal() }
            
            if error != nil {
                self.returnCode = -1
                return
            }
            //guard is used to ensure that we got proper response, in case return code not in 200-299 range we save it for later use
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                self.returnCode = (response as? HTTPURLResponse)?.statusCode ?? -2
                return
            }
            //if we got different responde type than JSON which is expected
            guard let mime = response.mimeType, mime == "application/json" else {
                self.returnCode = -3
                return
            }
            //try to parse response from JSON and extract JWT token
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: String]
                if let receivedToken = json?["access_token"] {
                    dataReceived = receivedToken
                }
                if let receivedTokenR = json?["refresh_token"] {
                    DispatchQueue.main.async {
                        self.defaults.set("Bearer \(receivedTokenR)", forKey: "authTokenRefresh")
                    }
                }
            } catch {
                self.returnCode = -4
                return
            }
        }
        task.resume()
        
        sem.wait()
        //returning token or conditional empty string?
        return dataReceived
    }
    
    //method used for checking if user session is still active, in addition it updates push interval value for current user as it may change quite often. If sesstion was terminated on server side or just expired user is being auto logout
    func isTokenValid(){
        let url = URL(string: ipAddr + "/users/me/validate")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                if let interval = json?["push_interval"] {
                    DispatchQueue.main.async {
                        self.defaults.set(interval as! Int, forKey: "pushInterval")
                        self.pushInterval = interval as! Int
                    }
                }
                if let message = json?["msg"] {
                    if (message as! String == "Token has expired" || message as! String == "Token has been revoked"){
                        DispatchQueue.main.async {
                            self.prolongateSession()
                        }
                    }
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    func prolongateSession(){
        let url = URL(string: ipAddr + "/refresh")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authTokenRefresh"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "POST"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
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
                if let message = json?["msg"] {
                    if (message as! String == "Token has expired" || message as! String == "Token has been revoked"){
                        DispatchQueue.main.async {
                            self.logout()
                            self.autoLogout = true
                        }
                    }
                }
            } catch {
                return
            }
        }
        task.resume()
    }
    
    func uploadApnDeviceToken(){
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/register/apn")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        let body = ["apn": myToken] as [String : String]
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
        }
        task.resume()
    }
    
    func revokeApnDeviceToken(){
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/revoke/apn")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        let currentToken = defaults.string(forKey: "apnToken") ?? "none"
        if (currentToken == "none"){
            return
        }
        let body = ["apn": myToken] as [String : String]
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        request.httpMethod = "DELETE"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
        }
        task.resume()
    }
    
    //method handling getting basic user info from derver just after successfull login -> name, surname, phone number, usrname, push interval and boolean if user is one time user or regular user with full data in DB
    func getUserData(){
        DispatchQueue.main.async {
            self.loadingUserData = .loading
        }
        let url = URL(string: ipAddr + "/users/me")!
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
                    self.loadingUserData = .failed
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                if let interval = json?["push_interval"] {
                    DispatchQueue.main.async {
                        self.defaults.set(interval as! Int, forKey: "pushInterval")
                        self.pushInterval = interval as! Int
                    }
                }
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
                if let phone = json?["phone"] {
                    DispatchQueue.main.async {
                        self.defaults.set(phone, forKey: "phone")
                    }
                }
                if let username = json?["username"] {
                    DispatchQueue.main.async {
                        self.defaults.set(username, forKey: "username")
                    }
                }
                if let uuid = json?["id"] {
                    DispatchQueue.main.async {
                        self.defaults.set(uuid, forKey: "uuid")
                    }
                }
                if let isOneTime = json?["one_time_user"] {
                    DispatchQueue.main.async {
                        self.defaults.set(isOneTime, forKey: "oneTimeUser")
                        self.loadingUserData = .loaded
                    }
                }
                if let experimentalFeatures = json?["experimental_features"] {
                    DispatchQueue.main.async {
                        let areOn: Bool = experimentalFeatures as! Bool
                        self.defaults.set(areOn, forKey: "experimentalFeatures")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingUserData = .failed
                }
                return
            }
        }
        task.resume()
    }
    
    //it just revoke token on server in case of logout button click
    func revokeToken(){
        let url = URL(string: ipAddr + "/logout")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "DELETE"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                return
            }
        }
        task.resume()
    }
    
}
