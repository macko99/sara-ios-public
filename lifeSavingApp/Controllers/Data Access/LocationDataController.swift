//
//  DAL class for storing and obtaing location data (collected from device GPS) to dev memory
//
//  StoredLocation is data cached from UserLocationController, it is going to be send ASAP and deleted
//  Storedpath is data stored in purpose to display path that user has walked so it is ment to be held on longer term
//  LocationDataController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 28/04/2021.
//

import Foundation
import CoreData
import CoreLocation

class LocationDataController {
    
    let persistentContainer = NSPersistentContainer(name: "LocationsData")
    
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
    
    //used for storing list of unsend locations
    func storeManyLocations(location: [StoredLocation]) throws {
        for loc in location{
            try storeLocation(location: loc)
        }
    }
    
    //save just one unsend location
    func storeLocation(location: StoredLocation) throws {
        self.context.insert(location)
        try self.context.save()
    }
    
    //store point as part of future path
    private func storePathPoint(pathPoint: StoredPath) throws {
        self.context.insert(pathPoint)
        try self.context.save()
    }
    
    //converter between CLLocation data from system location service and StoredLocation which is able to be saved in dev mem
    func storeLocation(location: CLLocation) throws {
        let newLocation = StoredLocation(context: self.context)
        newLocation.altitude = location.altitude
        newLocation.longitude = location.coordinate.longitude
        newLocation.course = location.course
        newLocation.courseAcc = location.courseAccuracy
        newLocation.horizontalAcc = location.horizontalAccuracy
        newLocation.speed = location.speed
        newLocation.speedAcc = location.speed
        newLocation.timestamp = Int32(location.timestamp.timeIntervalSince1970)
        newLocation.verticalAcc = location.verticalAccuracy
        newLocation.latitude = location.coordinate.latitude
        
        try storeLocation(location: newLocation)
    }
    
    //converter between CLLocation data from system location service and StoredPath which is able to be saved in dev mem
    func storePathPoint(pathPoint: CLLocation, action: Int) throws {
        let newPathPoint = StoredPath(context: self.context)
        newPathPoint.longitude = pathPoint.coordinate.longitude
        newPathPoint.timestamp = Int32(pathPoint.timestamp.timeIntervalSince1970)
        newPathPoint.latitude = pathPoint.coordinate.latitude
        newPathPoint.action = Int32(action)
        
        try storePathPoint(pathPoint: newPathPoint)
    }
    
    //deletes all StoredLocation data - so cached location points
    func deleteAll(){
        let fetchRequest = StoredLocation.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        var deleteRequest: NSBatchDeleteRequest
        deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        context.performAndWait{
            do{
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch {}
        }
    }
    
    func deleteAllPathElements(){
        let fetchRequest = StoredPath.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        context.performAndWait{
            do{
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch {}
        }
    }
    
    //gets all StoredLocation data - so cached location points
    func getAll() throws -> [StoredLocation] {
        let storedLocations = try self.context.fetch(StoredLocation.fetchRequest() as NSFetchRequest<StoredLocation>)
        return storedLocations
    }
    
    //gets all StoredLocation data - so cached location points with conversion to system type CLLocationCoordinate2D (point)
    func getAll() throws -> [CLLocationCoordinate2D] {
        let storedLocation: [StoredLocation] = try getAll()
        var coords = [] as [CLLocationCoordinate2D]
        for coord in storedLocation{
            coords.append(CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))
        }
        return coords
    }
    
    //gets user paths made out of points in device memory
    func getUserPath() throws -> [StoredPath] {
        let storedPaths = try self.context.fetch(StoredPath.fetchRequest() as NSFetchRequest<StoredPath>)
        return storedPaths
    }
    
    //gets user paths made out of points in device memory
    func getUserPathForAction(action: Int) throws -> [StoredPath] {
        let request = NSFetchRequest<StoredPath>(entityName: "StoredPath")
        request.predicate = NSPredicate(format: "action == %i", Int32(action))
        let storedPaths = try self.context.fetch(request)
        return storedPaths
    }
    
    //gets user paths made out of points in device memory - conversion to result set: list of lists
    func getUserPath() throws -> [[CLLocationCoordinate2D]] {
        var result = [] as [[CLLocationCoordinate2D]]
        
        //get all stored path points and sort them accrding to timestamp
        var storedPath: [StoredPath] = try getUserPath()
        storedPath.sort {
            $0.timestamp < $1.timestamp
        }
        
        var startIndex = 0
        
        //LOGIC: divide sotred points into groups (seperate paths) due to time interval between two sequential points. If interval is grater then 10 minutes we consider it as new path therefore we will draw two seperate lines on map
        for index in 0...storedPath.count-2{
            if (storedPath[index+1].timestamp - storedPath[index].timestamp > 600) || index == storedPath.count-2{
                result.append(Array(storedPath[startIndex...index]).toLocation())
                startIndex = index+1
            }
        }
        return result
    }
    
    func getUserPath(action: Int) throws -> [[CLLocationCoordinate2D]] {
        var result = [] as [[CLLocationCoordinate2D]]
        
        //get all stored path points and sort them accrding to timestamp
        var storedPath: [StoredPath] = try getUserPathForAction(action: action)
        storedPath.sort {
            $0.timestamp < $1.timestamp
        }
        
        var startIndex = 0
        
        //LOGIC: divide sotred points into groups (seperate paths) due to time interval between two sequential points. If interval is grater then 10 minutes we consider it as new path therefore we will draw two seperate lines on map
        for index in 0...storedPath.count-2{
            if (storedPath[index+1].timestamp - storedPath[index].timestamp > 600) || index == storedPath.count-2{
                result.append(Array(storedPath[startIndex...index]).toLocation())
                startIndex = index+1
            }
        }
        return result
    }
    
    //gets user paths made out of points in device memory - conversion to result set: dict with lists -> each lists of points is put into dict under key -> key is timestamp of first point in path so basically time of start of this path)
    func getUserPath() throws -> [Int : [CLLocationCoordinate2D]] {
        var result = [Int : [CLLocationCoordinate2D]]()
        
        //get all stored path points and sort them accrding to timestamp
        var storedPath: [StoredPath] = try getUserPath()
        if !storedPath.isEmpty && storedPath.count > 2{
            storedPath.sort {
                $0.timestamp < $1.timestamp
            }
            
            var startIndex = 0
            
            //LOGIC: divide sotred points into groups (seperate paths) due to time interval between two sequential points. If interval is grater then 10 minutes we consider it as new path therefore we will draw two seperate lines on map
            for index in 0...storedPath.count-2{
                if (storedPath[index+1].timestamp - storedPath[index].timestamp > 600) || index == storedPath.count-2{
                    result[Int(storedPath[startIndex].timestamp)] = Array(storedPath[startIndex...index]).toLocation()
                    startIndex = index+1
                }
            }
        }
        return result
    }
    
    func getUserPath(action: Int) throws -> [Int : [CLLocationCoordinate2D]] {
        var result = [Int : [CLLocationCoordinate2D]]()
        
        //get all stored path points and sort them accrding to timestamp
        var storedPath: [StoredPath] = try getUserPathForAction(action: action)
        if !storedPath.isEmpty && storedPath.count > 2{
            storedPath.sort {
                $0.timestamp < $1.timestamp
            }
            
            var startIndex = 0
            
            //LOGIC: divide sotred points into groups (seperate paths) due to time interval between two sequential points. If interval is grater then 10 minutes we consider it as new path therefore we will draw two seperate lines on map
            for index in 0...storedPath.count-2{
                if (storedPath[index+1].timestamp - storedPath[index].timestamp > 600) || index == storedPath.count-2{
                    result[Int(storedPath[startIndex].timestamp)] = Array(storedPath[startIndex...index]).toLocation()
                    startIndex = index+1
                }
            }
        }
        return result
    }
}
