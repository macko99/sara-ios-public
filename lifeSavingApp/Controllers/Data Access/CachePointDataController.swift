//
//  CachePointDataController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/10/2021.
//

import Foundation
import CoreData
import SwiftUI

class CachePointDataController {
    
    let persistentContainer = NSPersistentContainer(name: "CacheData")
    let defaults = UserDefaults.standard
    
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
    
    private func prepareCachedPoint(body: TemporaryPoint) -> CachedPoint{
        var newPoint = CachedPoint()
        context.performAndWait{
            newPoint = CachedPoint(context: self.context)
            newPoint.uuid = body.uuid
            newPoint.descriptionText = body.descriptionText
            newPoint.timestamp = Int32(body.timestamp)
            newPoint.latitude = body.latitude
            newPoint.longitude = body.longitude
            newPoint.blob = body.blob
            newPoint.action = Int16(body.action)
            newPoint.kind = Int16(body.kind)
            newPoint.type = body.type
            newPoint.name = body.name
        }
        return newPoint;
    }
    
    func storePointToCache(point: TemporaryPoint) {
        context.performAndWait{
            let properPoint = self.prepareCachedPoint(body: point)
            self.context.insert(properPoint)
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    
    func getAllPoints() -> [TemporaryPoint] {
        var result = [TemporaryPoint]()
        context.performAndWait{
            do{
                let pointInMemory: [CachedPoint] = try self.getAllPoints()
                result = pointInMemory.toTemporaryPoints()
            } catch{}
        }
        return result
    }
    
    private func getAllPoints() throws-> [CachedPoint] {
        return try self.context.fetch(CachedPoint.fetchRequest() as NSFetchRequest<CachedPoint>)
    }
    
    private func getPoint (uuid: String) throws -> CachedPoint? {
        let request = NSFetchRequest<CachedPoint>(entityName: "CachedPoint")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        
        let points = try self.context.fetch(request)
        if points.isEmpty{
            return nil
        }
        return points[0]
    }
    
    func deleteAllPoints() {        
        context.performAndWait{
            do{
                let fetchRequest = CachedPoint.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch{}
        }
    }
    
    //it deletes cached point with specific uuid from dev mem
    func deletePoint (uuid: String) {
        context.performAndWait{
            do{
                let p = try getPoint(uuid: uuid)
                if (p == nil){
                    return
                }
                self.context.delete(p!)
                try self.context.save()
            } catch{}
        }
    }
    
    private func preparePointBodyData(tmpPoint: TemporaryPoint) -> [String: Any]{
        var body = [String : Any]()
        context.performAndWait{
            body = ["action": Int(tmpPoint.action),
                    "uuid": tmpPoint.uuid,
                    "extension": tmpPoint.type,
                    "blob": tmpPoint.blob == Data.empty ? "" : tmpPoint.blob.base64EncodedString(options: .lineLength64Characters),
                    "longitude": tmpPoint.longitude,
                    "latitude": tmpPoint.latitude,
                    "time": tmpPoint.timestamp,
                    "name": tmpPoint.name,
                    "kind": tmpPoint.kind,
                    "description": tmpPoint.descriptionText] as [String : Any]
        }
        return body
    }
    
    func sendData(body: TemporaryPoint) -> (UpdateResult, CustomPoint){
        let result = sendData(body: preparePointBodyData(tmpPoint: body))
        var customPoint = CustomPoint.example
        context.performAndWait{
            customPoint = body.toBasicCustomPoint
        }
        customPoint.id = result.1
        customPoint.userID = result.2
        return (result.0, customPoint)
    }
    
    //http post reqest handler
    private func sendData(body: [String: Any]) -> (UpdateResult, Int, String){
        let sem = DispatchSemaphore.init(value: 0)
        var result: UpdateResult = .waiting
        var idFromDB = -1
        var uuidFromDB = "none"
        var iHappy = 0
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/actions/resources")!
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
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30 //MARK: timeoutIntervalForRequest for sending blob
        let session = URLSession(configuration: configuration)
        
        //        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            defer { sem.signal() }
            
            if error != nil {
                result = .failed
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                if let msg = json?["msg"] {
                    if (msg as! String == "data saved"){
                        iHappy += 1
                    }
                }
                if let id = json?["id"] {
                    if (id as? Int != nil){
                        iHappy += 1
                        idFromDB = id as! Int
                    }
                }
                if let uuid = json?["uid"] {
                    uuidFromDB = uuid as? String ?? uuidFromDB
                    iHappy += 1
                }
                if (iHappy == 3){
                    result = .success
                    return
                }
            } catch {
                result = .failed
                return
            }
        }
        task.resume()
        
        sem.wait()
        return (result, idFromDB, uuidFromDB)
    }
    
}
