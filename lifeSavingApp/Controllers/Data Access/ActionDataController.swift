//
//  DAL class resposible for providing actions (including points, areas, corrdinates...etc) data available in device memory in a understanable wat which is easy to use in code. Abstarction level between SQL Lite-ish data in iOS device and high level data structures used in higher controllers and views
//
//  Whenever I use "Db type" in this class I mean object which data structure is close representation of data stored in device memoy. "code type" or similar expresion means data which structure is good to use it in higer classes such as views.
//
//  ActionDataController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//

import Foundation
import CoreData
import CoreLocation

class ActionDataController {
    
    let persistentContainer = NSPersistentContainer(name: "ActionsData")
    
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
    
    //insert one action into device memory
    private func storeAction(action: StoredAction) throws {
        self.context.insert(action)
        try self.context.save()
    }
    
    //converts Action data type (coding) into StoredAction (DB type)
    func storeAction(action: Action) {
        context.performAndWait{
            let newAction = StoredAction(context: self.context)
            newAction.longitude = action.longitude
            newAction.id = Int16(action.id)
            newAction.descriptionText = action.description
            newAction.name = action.name
            newAction.radius = action.radius
            newAction.startTime = Int32(action.start_time)
            newAction.isActive = action.is_active
            newAction.latitude = action.latitude
            do{
                try self.storeAction(action: newAction)
            } catch{}
        }
    }
    
    //update action details in device mem
    func updateAction(action: Action) throws {
        context.performAndWait{
            //we assume there is only one! ids are uniqe on backend side DB
            let toUpdateAction = self.getAction(id: action.id)!
            //upgare values
            toUpdateAction.longitude = action.longitude
            toUpdateAction.descriptionText = action.description
            toUpdateAction.name = action.name
            toUpdateAction.radius = action.radius
            toUpdateAction.startTime = Int32(action.start_time)
            toUpdateAction.isActive = action.is_active
            toUpdateAction.latitude = action.latitude
            //save
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //get all actions from dev mem in DB type (StoredAction)
    private func getAllActions() -> [StoredAction] {
        var storedActions = [StoredAction]()
        
        context.performAndWait{
            do{
                storedActions = try self.context.fetch(StoredAction.fetchRequest() as NSFetchRequest<StoredAction>)
            } catch{}
        }
        return storedActions
    }
    
    func getAllActionsIds() -> [Int16] {
        let storedActions: [StoredAction] = self.getAllActions()
        var storedActionsIds = [Int16]()
        
        context.performAndWait{
            storedActionsIds = storedActions.map { $0.id }
        }
        return storedActionsIds
    }
    
    //get all actions from dev mem and returns them as Action typed list orderd by startTime ascending
    func getAllActions() -> [Action] {
        var storedActions: [StoredAction] = getAllActions()
        var actions = [Action]()
        
        context.performAndWait{
            storedActions.sort(by: { $0.startTime < $1.startTime })
            actions = storedActions.map { $0.toAction }
        }
        return actions
    }
    
    //it deletes action with specific id from dev mem
    func deleteAction (id: Int) {
        context.performAndWait{
            let action = getAction(id: id)
            
            //delete and save
            self.context.delete(action!)
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //it gets just one action with scpecific id from dev mem
    private func getAction (id: Int) -> StoredAction? {
        let request = NSFetchRequest<StoredAction>(entityName: "StoredAction")
        request.predicate = NSPredicate(format: "id == %i", id)
        
        var action = [StoredAction]()
        do{
            action = try self.context.fetch(request)
        } catch{}
        
        if action.isEmpty{
            return nil
        }
        return action[0]
    }
    
    func getActionCoords (id: Int) -> ActionCoords {
        var resultCoords = ActionCoords()
        context.performAndWait{
            let action = self.getAction(id: id)!
            resultCoords.latitude = action.latitude
            resultCoords.longitude = action.longitude
            resultCoords.radius = action.radius
        }
        return resultCoords
    }
    
    //POWERFUL, it deletes all actions from device memory.
    func deleteAllActions() {
        context.performAndWait{
            let fetchRequest = StoredAction.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do{
                try self.context.execute(deleteRequest)
                try self.context.save()
            }catch{}
        }
    }
    
    //it adds new are to action in dev memory
    func addAreaToAction(actionId: Int, name: String, id: Int) {
        context.performAndWait{
            let area = StoredArea(context: self.context)
            area.name = name
            area.id = Int16(id)
            
            let action = self.getAction(id: actionId)
            action!.addToAreas(area)
            
            do{
                try self.context.save()
            }
            catch{}
        }
    }
    
    //it gets aras for specific action from dev mem and retuns them as StoredArea list
    private func getActionAreas(actionId: Int) -> [StoredArea] {
        var result = [StoredArea]()
        context.performAndWait{
            let action = self.getAction(id: actionId)!
            result = Array(action.areas ?? [])
        }
        return result
    }
    
    //it gets aras for specific action from dev mem and retuns them as StoredArea list
    func getActionAreas(actionId: Int) -> [SimpleArea] {
        return self.getActionAreas(actionId: actionId).toSimpleArea()
    }
    
    func getActionAreasIds(actionId: Int) -> [Int16] {
        var storedAreasIds = [Int16]()
        context.performAndWait{
            let storedAreas: [StoredArea] = self.getActionAreas(actionId: actionId)
            storedAreasIds = storedAreas.map { $0.id }
        }
        return storedAreasIds
    }
    
    //gets all areas in dev mem
    func getAllAreas() throws -> [StoredArea] {
        var storedArea = [StoredArea]()
        context.performAndWait{
            do{
                storedArea = try self.context.fetch(StoredArea.fetchRequest() as NSFetchRequest<StoredArea>)
            } catch{}
        }
        return storedArea
    }
    
    //gets just one area with specific id
    private func getArea (id: Int) -> StoredArea {
        var areas = [StoredArea]()
        
        let request = NSFetchRequest<StoredArea>(entityName: "StoredArea")
        request.predicate = NSPredicate(format: "id == %i", id)
        
        context.performAndWait{
            do{
                areas = try self.context.fetch(request)
            }
            catch{}
        }
        return areas[0]
    }
    
    //gets just one cooridnate with specific id from dev mem and returns as DB type StoredCoordinate
    private func getCoordinate (id: Int) -> StoredCoordinate {
        var coords = [StoredCoordinate]()
        
        let request = NSFetchRequest<StoredCoordinate>(entityName: "StoredCoordinate")
        request.predicate = NSPredicate(format: "id == %i", id)
        
        
        context.performAndWait{
            do{
                coords = try self.context.fetch(request)
            }
            catch{}
        }
        return coords[0]
    }
    
    //deletes just one area from dev mem
    func deleteArea(id: Int) {
        let removedArea = getArea(id: id)
        
        context.performAndWait{
            self.context.delete(removedArea)
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //gets all coordinates in dev mem as
    func getAllCoordinates() throws -> [StoredCoordinate] {
        var storedCoordinates = [StoredCoordinate]()
        context.performAndWait{
            do{
                storedCoordinates = try self.context.fetch(StoredCoordinate.fetchRequest() as NSFetchRequest<StoredCoordinate>)
            } catch{}
        }
        return storedCoordinates
    }
    
    //gets cooridnates for specific area
    func getAreaCoordinates (areaId: Int) throws -> [Coordinates] {
        let area = getArea(id: areaId)
        return Array(area.coordinates ?? []).toCoordinates()
    }
    
    //it adds cooridnates list to specific area
    func addCoordinatesToArea(areaId: Int, cooridnates: [Coordinates]) {
        let area = getArea(id: areaId)
        
        context.performAndWait{
            for coordinate in cooridnates{
                let newCoordinate = StoredCoordinate(context: self.context)
                newCoordinate.latitude = coordinate.latitude
                newCoordinate.longitude = coordinate.longitude
                newCoordinate.id = Int16(coordinate.id)
                newCoordinate.order = Int16(coordinate.order)
                area.addToCoordinates(newCoordinate)
            }
            
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //it adds just one cooridnates object to area
    func addCoordinateToArea(areaId: Int, coordinate: Coordinates){
        let area = getArea(id: areaId)
        context.performAndWait{
            let newCoordinate = StoredCoordinate(context: self.context)
            newCoordinate.latitude = coordinate.latitude
            newCoordinate.longitude = coordinate.longitude
            newCoordinate.id = Int16(coordinate.id)
            newCoordinate.order = Int16(coordinate.order)
            area.addToCoordinates(newCoordinate)
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //it removes just one cooridnate object from area
    func removeCoordinateFromArea(areaId: Int, coordinateId: Int) {
        let area = getArea(id: areaId)
        let oldCordinate = getCoordinate(id: coordinateId)
        
        context.performAndWait{
            area.removeFromCoordinates(oldCordinate)
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //it adds point to action
    func addPointToAction(actionId: Int, pointData: CustomPoint){
        context.performAndWait{
            let action = getAction(id: actionId)
            let newPoint = StoredPoint(context: self.context)
            newPoint.descriptionText = pointData.description
            newPoint.id = Int16(pointData.id)
            newPoint.latitude = pointData.latitude
            newPoint.type = pointData.ext
            newPoint.longitude = pointData.longitude
            newPoint.name = pointData.name
            newPoint.timestamp = Int32(pointData.time)
            newPoint.uuid = pointData.uuid
            newPoint.userID = pointData.userID
            newPoint.kind = Int16(pointData.kind)
            action!.addToPoints(newPoint)
            
            //save
            do{
                try self.context.save()
            } catch{}
        }
    }
    
    //it gets all points for specific action
    func getActionPoints(actionId: Int) {
        let points = Array(getAction(id: actionId)!.points ?? [])
        
        for point in points{
            let type = AnnotationType(rawValue: Int(point.kind)) ?? .bellAnnotation
            let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2DMake(point.latitude, point.longitude),
                                              name: point.name!.isEmpty ? "Empty" : point.name!,
                                              descriptionText: point.descriptionText!,
                                              time: Int(point.timestamp),
                                              type: type,
                                              user: point.userID!,
                                              id: Int(point.id),
                                              resourceUID: point.uuid!)
            mapView.addAnnotation(annotation)
        }
    }
    
    func getActionPointsIds(actionId: Int) throws -> [Int16] {
        var actionPointsIds = [Int16]()
        context.performAndWait{
            let action = getAction(id: actionId)
            actionPointsIds = Array(action!.points ?? []).map { $0.id }
        }
        return actionPointsIds
    }
    
    //it gets all points in dev mem
    func getAllPoints() -> [StoredPoint] {
        var storedPoints = [StoredPoint]()
        context.performAndWait{
            do{
                storedPoints = try self.context.fetch(StoredPoint.fetchRequest() as NSFetchRequest<StoredPoint>)
            } catch{}
        }
        return storedPoints
    }
    
    //it gets just one point by its id
    private func getPoint (id: Int) throws -> StoredPoint? {
        let request = NSFetchRequest<StoredPoint>(entityName: "StoredPoint")
        request.predicate = NSPredicate(format: "id == %i", id)
        
        let point = try self.context.fetch(request)
        
        if (point.isEmpty){
            return nil
        }
        return point[0]
    }
    
    //it gets just one point by its uuid (differnet column in Db -> from backend)
    private func getPoint (uuid: Int) throws -> StoredPoint {
        let request = NSFetchRequest<StoredPoint>(entityName: "StoredPoint")
        request.predicate = NSPredicate(format: "uuid == %i", uuid)
        
        let point = try self.context.fetch(request)
        return point[0]
    }
    
    //its remove just one point by its id
    func deletePoint(id: Int) {
        context.performAndWait{
            do{
                let removedPoint = try getPoint(id: id)
                
                self.context.delete(removedPoint!)
                try self.context.save()
            } catch{}
        }
    }
    
    //    //it update points data -> input: spcecifit "code type" point
    //    func updatePoint(point: CustomPoint) throws {
    //        let toUpdatePoint = try getPoint(id: point.id)
    //
    //        if(toUpdatePoint == nil){
    //            return
    //        }
    //
    //        toUpdatePoint!.longitude = point.longitude
    //        toUpdatePoint!.descriptionText = point.description
    //        toUpdatePoint!.name = point.name
    //        toUpdatePoint!.latitude = point.latitude
    //        toUpdatePoint!.uuid = point.uuid
    //        toUpdatePoint!.type = point.ext
    //        toUpdatePoint!.userID = point.userID
    //        toUpdatePoint!.timestamp = Int32(point.time)
    //        toUpdatePoint!.kind = Int16(point.kind)
    //
    //        if(toUpdatePoint != nil){
    //
    //            try self.context.save()
    //        }
    //    }
    
    //it saves image to dev mem with link to specific point
    func saveImagetoPoint(pointId: Int, data: Data) {
        context.performAndWait{
            do{
                let toUpdatePoint = try getPoint(id: pointId)
                toUpdatePoint!.blob = data
                try self.context.save()
            } catch{}
        }
    }
    
    //gets image from dev mem by its uid
    func getImageForPoint(imageUUID: String) -> Data? {
        let request = NSFetchRequest<StoredPoint>(entityName: "StoredPoint")
        request.predicate = NSPredicate(format: "uuid == %@", imageUUID)
        var result: Data = Data.notLoaded
        
        context.performAndWait{
            do{
                let pointWithImage = try self.context.fetch(request)
                if !pointWithImage.isEmpty{
                    result = pointWithImage[0].blob ?? Data.notLoaded
                }
            } catch{}
        }
        return result
    }
    
    //removes all points from dem mem
    func deleteAllPoints() {        
        context.performAndWait{
            let fetchRequest = StoredPoint.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do{
                try self.context.execute(deleteRequest)
                try self.context.save()
            } catch{}
        }
    }
    
}
