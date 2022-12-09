//
//  this class is responsible for obtaining user location from system services (gps...etc) and sending it to server as well as caching in local device memory in case of offline mode. it also stores those locations in dev memory to be used on map as poinits to draw walked paths
//
//  UserLocationController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 26/04/2021.
//

import Foundation
import CoreLocation
import Combine
import UIKit

class UserLocationController: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    let didChange = PassthroughSubject<UserLocationController,Never>()
    let willChange = PassthroughSubject<UserLocationController,Never>()
    //DAL for handling caching in device memory
    let locationDataController = LocationDataController()
    //using system defaults
    let defaults = UserDefaults.standard
    
    //system location servie
    private let locationManager = CLLocationManager()
    private var returnCode = -1
    //info about last uplodaing data success
    private var lastTime = 0
    private var lastState = LastState.ok
    //public values available on observable object of this class
    @Published var lastLocation: CLLocation?
    @Published var connectionSuccessTime: String?
    @Published var isActive: Bool
    
    //prepare system location service and read last time of successfull upload from defaults
    override init() {
        isActive = false
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.allowsBackgroundLocationUpdates=true
        locationManager.pausesLocationUpdatesAutomatically=false
        locationDataController.initalizeStack()
        connectionSuccessTime = defaults.string(forKey: "connectionTime") ?? "-"
        isActive = defaults.bool(forKey: "GPSisActive")
        if (isActive){
            resumeLocationService()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(cleanCoreDataOnLogout(_:)), name: .didLogOut, object: nil)
    }
    
    @objc func cleanCoreDataOnLogout(_ notification: Notification){
        locationDataController.deleteAll()
        locationDataController.deleteAllPathElements()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    }
    
    //this fucs is called every time system location service detects change in location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        //get current location (or last known)
        //try to store it!
        storeLocation(receivedLocation: location)
    }
    
    func killLocationService() {
        locationManager.stopUpdatingLocation()
        defaults.set(false, forKey: "GPSisActive")
    }
    
    func resumeLocationService() {
        locationManager.startUpdatingLocation()
        defaults.set(true, forKey: "GPSisActive")
    }
    
    func resumeLocationServiceIfTurnOn() {
        let isOn = defaults.bool(forKey: "GPSisActive")
        if (isOn){
            locationManager.startUpdatingLocation()
        }
    }
    
    func checkLocationService() -> Bool{
        switch locationManager.authorizationStatus {
        case .notDetermined, .restricted, .denied, .authorizedWhenInUse:
            return false
        case .authorizedAlways:
            return true
        @unknown default:
            return false
        }
    }
    
    //this method received new location on every change and hande logic behind uploading it and saving in cache
    func storeLocation(receivedLocation: CLLocation) {
        //timestamp of this new location data
        let receivedTime = Int(receivedLocation.timestamp.timeIntervalSince1970)
        //pushing interval for current user
        let interval = defaults.integer(forKey: "pushInterval")
        
        //check if we meet the requirements for sending location
        if(receivedTime - lastTime > interval && ( lastLocation == nil || (lastLocation != nil && receivedLocation.distance(from: lastLocation!) > 5))){
            lastTime = receivedTime
            lastLocation = receivedLocation
            
            do{
                let actionId = defaults.integer(forKey: "currentAction")
                //save point to dev memory to then be displayed on map
                //MARK: USE 1 FOR DATA WITHOUT ACTION REF - DUMMY ACTION IN DB, SHOULD NOT HAPPEN BUT...
                _ = try locationDataController.storePathPoint(pathPoint: receivedLocation, action: actionId < 1 ? 1 : actionId)
            }
            catch{}
            //try uploading to server
            let sendResult = sendLocation(lastLocation: receivedLocation)
            
            switch sendResult {
            case 200:
                //if sent successfully update last sucessfull upload time and try sending all cached data that hasnt been upload before
                updateConnectionSuccessTime(timestamp: receivedTime)
                if (lastState != .ok){
                    sendUnsavedLocations()
                    lastState = .ok
                }
            case -1:
                //not uploded - store location point in cache
                lastState = .network
                storeUnsendLocation(receivedLocation: receivedLocation)
            default:
                //not uploded - store location point in cache
                lastState = .error
                storeUnsendLocation(receivedLocation: receivedLocation)
            }
        }
    }
    
    func updateConnectionSuccessTime(timestamp: Int){
        connectionSuccessTime = timestamp.toDateStringVeryShort
        defaults.set(connectionSuccessTime, forKey: "connectionTime")
    }
    
    //not uploded - store location point in cache
    func storeUnsendLocation(receivedLocation: CLLocation) {
        do{
            try locationDataController.storeLocation(location: receivedLocation)
        }
        catch{}
    }
    
    //uploading cached data to server
    func sendUnsavedLocations() {
        
        do{
            //get cached data from device memory
            let unsendLocations : [StoredLocation] = try locationDataController.getAll()
            var stillToBeSend: [StoredLocation] = []
            
            for loc in unsendLocations{
                //enumarate cached locations and try to upload
                let response = sendLocation(lastLocation: loc)
                if (response != 200){
                    //if upload failed again save this location point to stillToBeSend list
                    lastState = .unsend
                    stillToBeSend.append(loc)
                }
            }
            //empty location cache
             locationDataController.deleteAll()
            //store to cache items from stillToBeSend
            try locationDataController.storeManyLocations(location: stillToBeSend)
        }
        catch{}
    }
    
    //converter: StoredLocation into bare object [String: Any] (from dev memory to server)
    func sendLocation(lastLocation: StoredLocation) -> Int{
        return sendData(body:
                            prepareLocationBodyData(long: lastLocation.longitude,
                                                    lati: lastLocation.latitude,
                                                    time: Int(lastLocation.timestamp),
                                                    speed_acc: lastLocation.speedAcc,
                                                    horizontal_acc: lastLocation.horizontalAcc,
                                                    vertical_acc: lastLocation.verticalAcc,
                                                    speed: lastLocation.speed,
                                                    course: lastLocation.course,
                                                    course_acc: lastLocation.courseAcc,
                                                    altidute: lastLocation.altitude))
    }
    
    //converter: CLLocation into bare object [String: Any] (from system location service to server)
    func sendLocation(lastLocation: CLLocation) -> Int{
        return sendData(body:
                            prepareLocationBodyData(long: lastLocation.coordinate.longitude,
                                                    lati: lastLocation.coordinate.latitude,
                                                    time: Int(lastLocation.timestamp.timeIntervalSince1970),
                                                    speed_acc: lastLocation.speedAccuracy,
                                                    horizontal_acc: lastLocation.horizontalAccuracy,
                                                    vertical_acc: lastLocation.verticalAccuracy,
                                                    speed: lastLocation.speed,
                                                    course: lastLocation.course,
                                                    course_acc: lastLocation.courseAccuracy,
                                                    altidute: lastLocation.altitude))
    }
    
    //prepare data to be uploaded -> create obcject which can be easily converted into JSON object and add current action id to data
    func prepareLocationBodyData(long: Double, lati: Double, time: Int, speed_acc: Double, horizontal_acc: Double, vertical_acc: Double,
                                 speed: Double, course: Double, course_acc: Double, altidute: Double) -> [String: Any]{
        let actionId = defaults.integer(forKey: "currentAction")
        let body = ["latitude": lati,
                    "longitude": long,
                    "time": time,
                    "speed": speed,
                    "course_accuracy": course_acc,
                    "speed_accuracy": speed_acc,
                    "horizontal_accuracy": horizontal_acc,
                    "vertical_accuracy": vertical_acc,
                    "altitude": altidute,
                    "course": course,
                    "action": (actionId < 1 ? 1 : actionId), //MARK: USE 1 FOR DATA WITHOUT ACTION REF - DUMMY ACTION IN DB, SHOULD NOT HAPPEN BUT...
                    "width": defaults.integer(forKey: "observationWidth")] as [String : Any]
        return body
    }
    //http post reqest handler
    func sendData(body: [String: Any]) -> Int{
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/locations")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        let bodyData = try? JSONSerialization.data(
            withJSONObject: body,
            options: []
        )
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                self.returnCode = -1
            }
            if let response = response as? HTTPURLResponse {
                self.returnCode = response.statusCode
            }
        }
        task.resume()
        
        return self.returnCode
    }
}


