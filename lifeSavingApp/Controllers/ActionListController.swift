//
//  this class is responsible for fetching actions data from server (including areas, points, actions, coordinates data) and passing it next to proper Views and to ActionDataController which is responsible for saving and reading those data from device memory.
//
//  Data synchronization: "device memory - server - dispalying in viws" is crutial. This class is a bridge, abstarction level for data access between data available in views and data available in device memory and data available and received from server.
//
//  ActionListController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//

import Foundation
import Combine
import CoreLocation
import MapKit

class ActionListController: ObservableObject{
    
    //this class also uses ssystem defaults
    let defaults = UserDefaults.standard
    //declaration of action data controller - kind of DAL class
    let actionDataController = ActionDataController()
    let didChange = PassthroughSubject<ActionListController,Never>()
    let willChange = PassthroughSubject<ActionListController,Never>()
    //usr controller is moved out for the code to be more clear - it is resposible for handling user data synchronization with server
    let usersController = UsersController()
    //variable holding current user areas
    var myAreas = [Int]()
    let cachePointDataController = CachePointDataController()
    var myUUID: String?
    
    @Published var avatars = [String : Avatar]()
    
    //data avaialble on observable object of this class - used in flows on views
    @Published var currentAction = -1
    @Published var actionIsSet = false
    
    @Published var actionWasChanged = false
    @Published var actionDataWasRefreshed = 0
    //variable for mapView to be able to center on action when needed
    @Published var shouldBeActionInFocus = false
    //public variable holding current user areas
    @Published var actions = [Action]()
    //used for holding and presenting current state of reqests
    @Published var loadingStateActions = LoadingState.idle
    @Published var loadingStateAreas = LoadingState.idle
    @Published var loadingStatePoints = LoadingState.idle
    @Published var loadingStateMyAreas = LoadingState.idle
    
    @Published var loadingStateCache = LoadingState.idle
    
    var timer = Timer()
    
    //in init section we try to fetched data from device memory and also set current action if suer done it already before closing app
    init(){
        actionDataController.initalizeStack()
        actions = actionDataController.getAllActions()
        
        if (defaults.bool(forKey: "actionIsSet")) {
            currentAction = defaults.integer(forKey: "currentAction")
            actionIsSet = true
            self.startTimer()
        }
        
        let tryStoredMyAreas  = defaults.object(forKey: "myAreas") as? [Int]
        if (tryStoredMyAreas != nil){
            myAreas = tryStoredMyAreas!
        }
        
        //this is true only if launching app -> so we create this conrroller or user switched or join action
        shouldBeActionInFocus = true
        cachePointDataController.initalizeStack()
        
        NotificationCenter.default.addObserver(self, selector: #selector(cleanCoreDataOnLogout(_:)), name: .didLogOut, object: nil)
    }
    
    func startTimer(){
        self.timer = Timer.scheduledTimer(timeInterval: 600.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        timer.tolerance = 120.0//MARK: timer settings
    }
    
    @objc func cleanCoreDataOnLogout(_ notification: Notification){
        cachePointDataController.deleteAllPoints()
        actionDataController.deleteAllPoints()
    }
    
    func fillAvatarsList(){
        self.avatars = usersController.userDataController.getAllAvatars()
    }
    
    func getAvatar(isMine: Bool, uuid: String) -> Avatar{
        if isMine{
            return Avatar(color: "#ff8000", avatar: "")
        }
        return self.avatars[uuid] ?? Avatar(color: "#ff8000", avatar: "Monkey") //MARK: change
    }
    
    func GetMyUUID() -> String{
        if(myUUID != nil){
            return myUUID!
        }
        if (defaults.string(forKey: "uuid") != nil){
            myUUID = defaults.string(forKey: "uuid")!
            return myUUID!
        }
        return "-"
    }
    
    //method is used to store to device memory all new actions items as well as update them and remove items that are no longer on server
    func storeNewActions(actions: [Action]) throws {
        //actions currenty in devide memory
        let currentActionsIds: [Int16] = actionDataController.getAllActionsIds()
        
        //if memory contains items
        if !currentActionsIds.isEmpty{
            //get id-s of actions in memory and create list of actions to delete as list of all actions in device mem
            var toDelete = currentActionsIds
            
            //numerate actions provided to method (eg. fetched from server)
            for action in actions{
                let id = Int16(action.id)
                //if we dont have such an action in local storage - save it
                if !currentActionsIds.contains(id){
                    actionDataController.storeAction(action: action)
                }
                else{
                    //if we already have such an action - update it! and remove from list of actions to delete
                    toDelete = toDelete.filter { $0 != id }
                    try actionDataController.updateAction(action: action)
                }
            }
            //remove actions that are in device mem but no longer on server
            for id in toDelete{
                actionDataController.deleteAction(id: Int(id))
            }
        }
        //if device memory is empty simply save all items to it
        else{
            for action in actions{
                actionDataController.storeAction(action: action)
            }
        }
    }
    
    //method is used to store to device memory all new areas items for specific action as well as update them and remove items that are no longer on server
    func storeNewAreas(newAreas: [Area], actionId: Int) throws {
        //areas for specific action currenty in devide memory
        let currentAreasIds: [Int16] = actionDataController.getActionAreasIds(actionId: actionId)
        
        //if memory contains items
        if !currentAreasIds.isEmpty{
            //get id-s of areas in memory and create list of areas to delete as list of all areas (for action) in device mem
            var toDelete = currentAreasIds
            
            //numerate areas provided to method (eg. fetched from server)
            for area in newAreas{
                let id = Int16(area.area_id)
                //if we dont have such an action in local storage - save it and save its coordinates
                if !currentAreasIds.contains(id){
                    actionDataController.addAreaToAction(actionId: actionId, name: area.name, id: area.area_id)
                    actionDataController.addCoordinatesToArea(areaId: area.area_id, cooridnates: area.coordinates)
                }
                else{
                    //if we already have such an area - update its coordinates and remove from list of areas to delete
                    toDelete = toDelete.filter { $0 != id }
                    //                    _ = try updateCoordinatesForArea(areaId: area.area_id, cooridnates: area.coordinates)//MARK: not needed
                }
            }
            //remove areas that are in device mem but no longer on server
            for id in toDelete{
                actionDataController.deleteArea(id: Int(id))
            }
        }
        //if device memory is empty simply save all items to it
        else{
            for area in newAreas{
                actionDataController.addAreaToAction(actionId: actionId, name: area.name, id: area.area_id)
                actionDataController.addCoordinatesToArea(areaId: area.area_id, cooridnates: area.coordinates)
            }
        }
    }
    
    //method is used to store to device memory all new points items for specific action as well as update them and remove items that are no longer on server
    func storeNewPoints(points: [CustomPoint], actionId: Int) throws {
        //points for specific action currenty in devide memory
        let currentPointsIds: [Int16] = try actionDataController.getActionPointsIds(actionId: actionId)
        
        //if memory contains items
        if !currentPointsIds.isEmpty{
            //get id-s of points in memory and create list of areas to delete as list of all areas (for action) in device mem
            var toDelete = currentPointsIds
            
            //numerate points provided to method (eg. fetched from server)
            for customPoint in points{
                let id = Int16(customPoint.id)
                //if we dont have such an point in local storage - save it
                if !currentPointsIds.contains(id){
                    actionDataController.addPointToAction(actionId: actionId, pointData: customPoint)
                }
                else{
                    //if we already have such an point - update it
                    toDelete = toDelete.filter { $0 != id }
                    //                    _ = try actionDataController.updatePoint(point: customPoint)//MARK: not needed
                }
            }
            //remove points that are in device mem but no longer on server
            for id in toDelete{
                actionDataController.deletePoint(id: Int(id))
            }
        }
        //if device memory is empty simply save all items to it
        else{
            for customPoint in points{
                actionDataController.addPointToAction(actionId: actionId, pointData: customPoint)
            }
        }
    }
    
    //    //funtion handles logic behind updating coordinates for specific area
    //    func updateCoordinatesForArea(areaId: Int, cooridnates: [Coordinates]) throws -> Void {
    //        if cooridnates.isEmpty{
    //            return
    //        }
    //
    //        //get ids of coordinates currenty under specific action and make copy of this collectiont to toDelete variable
    //        let currentCoordinatesIds : [Int] = try actionDataController.getAreaCoordinates(areaId: areaId).map {$0.id}
    //        var toDelete = currentCoordinatesIds
    //        //numerate coordinates provided to function
    //        for coord in cooridnates{
    //            //if we dont have such cooridnate - add it to action
    //            if !currentCoordinatesIds.contains(coord.id){
    //                _ = try actionDataController.addCoordinateToArea(areaId: areaId, coordinate: coord)
    //            }
    //            else{
    //                //if we have it - do nothing, just do not remove it
    //                //FOR NOW CHANGIND COORIDNATE DATA IS NOT AVAILABLE ON SERVER LOGIC - IT WOULDNT HAVE MUCH SENSE TBH
    //                toDelete = toDelete.filter { $0 != coord.id }
    //            }
    //        }
    //        //remove all other coordinates from memory that are no longer on server
    //        for item in toDelete{
    //            actionDataController.removeCoordinateFromArea(areaId: areaId, coordinateId: item)
    //        }
    //    }
    
    //this method is used by view to show areas to user - it provides coordinates for all areas
    func getAllCoordinates(justMyAreas: Bool) throws -> [AreaUID : [CLLocationCoordinate2D]] {
        //result set is list with sublist (hashmap) -> areas with list of coordinates for each
        //we use cutom type AreaUID which is hashable
        var result = [AreaUID : [CLLocationCoordinate2D]]()
        
        //first we get (from dev mem) list of areas for current action
        var areas = actionDataController.getActionAreas(actionId: currentAction)
        if(justMyAreas){
            areas = areas.filter { myAreas.contains($0.area_id) }
        }
        else{//just not my
            areas = areas.filter { !myAreas.contains($0.area_id) }
        }
        for area in areas {
            //then we numare it and get (from dev mem) coordinates for each area
            var coords = try actionDataController.getAreaCoordinates(areaId: area.area_id)
            //we sort it according to column order (coordinates order is essential to draw corrent shape on map - it comes from DB)
            coords.sort {
                $0.order < $1.order
            }
            var sublist = [CLLocationCoordinate2D]()
            //and finally we save it to new sublist, already coreclty converted into CLLocationCoordinate2D obcject which is readble by map API
            for coord in coords{
                sublist.append(CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude))
            }
            //prepare result set -> fill AreaUID fields (isMine flag is important for user story), local myAreas list is used
            let areaUID = AreaUID(name: area.name.isEmpty ? "no area name" : area.name, isMine: justMyAreas, id: area.area_id)
            result[areaUID] = sublist
        }
        return result
    }
    
    //method handles http request for fetching actions from server
    func fetchActions() {
        self.loadingStateActions = .loading
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/actions")!
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
                    self.loadingStateActions = .failed
                }
                return
            }
            
            //if we got data back we try to parse it from JSON and decode using our custom ActionsResponse data type
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(ActionsResponse.self, from: data) {
                    DispatchQueue.main.async {
                        // actions save to local variable actions (previosly setting proper date format)
                        self.actions = decodedResponse.actions.sorted(by: { $0.start_time < $1.start_time})
                        self.loadingStateActions = .loaded
                    }
                    do{
                        //try storing data in device memory
                        try self.storeNewActions(actions: decodedResponse.actions)
                    }
                    catch{}
                    return
                }
            }
            DispatchQueue.main.async {
                self.loadingStateActions = .failed
            }
        }
        task.resume()
        getMyAreas()
    }
    
    //method handles http request for fetching actions from server
    func fetchPoints() {
        if !actionIsSet {
            return
        }
        DispatchQueue.main.async {
            self.loadingStatePoints = .loading
        }
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/resources/" + String(currentAction))!
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
                    self.loadingStatePoints = .failed
                }
                return
            }
            
            //if we got data back we try to parse it from JSON and decode using our custom PointsResponse data type
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(PointsResponse.self, from: data) {
                    do{
                        //try saving data to device mem
                        try self.storeNewPoints(points: decodedResponse.resources, actionId: self.currentAction)
                    }
                    catch{}
                    DispatchQueue.main.async {
                        self.loadingStatePoints = .loaded
                        self.actionDataWasRefreshed = (self.actionDataWasRefreshed + 1) % 10
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                self.loadingStatePoints = .failed
            }
        }
        task.resume()
    }
    
    //method handles http request for fetching areas for current action from server
    func fetchAreas(){
        if !actionIsSet {
            return
        }
        DispatchQueue.main.async {
            self.loadingStateAreas = .loading
        }
        
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/areas/" + String(currentAction))!
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
                    self.loadingStateAreas = .failed
                }
                return
            }
            
            //if we got data back we try to parse it from JSON and decode using our custom AreasResponse data type
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(AreasResponse.self, from: data) {
                    DispatchQueue.main.async {
                        self.loadingStateAreas = .loaded
                    }
                    do{
                        //try saving data to device mem
                        try self.storeNewAreas(newAreas: decodedResponse.areas, actionId: self.currentAction)
                    }
                    catch{}
                    return
                }
            }
            DispatchQueue.main.async {
                self.loadingStateAreas = .failed
            }
        }
        task.resume()
        fetchPoints()
        return
    }
    
    //small utility func to set current action id -> update system defaults
    func setCurrentAction(actionId: Int){
        //action was previously set but it was different -> we change action and remove old data from device
        if actionIsSet && currentAction != actionId{
            //MARK: TODO change action, remove old data! is it really nedded?
        }
        //we join new action, none action was joined before
        shouldBeActionInFocus = true
        currentAction = actionId
        defaults.set(actionId, forKey: "currentAction")
    }
    
    //small utility func to set actionIsSet flag -> update system defaults
    func setActionIsSet(isSet: Bool){
        //action was set previously but now we want to remove it -> remove old data from device -> we leave action
        if !isSet && actionIsSet {
            timer.invalidate()
            //MARK: TODO remove old action data! is it really nedded?
        }
        //we join new action
        else if isSet && !actionIsSet {
            self.startTimer()
        }
        //we just change action
        actionWasChanged = true
        actionIsSet = isSet
        defaults.set(isSet, forKey: "actionIsSet")
    }
    
    @objc func fireTimer(){
        fetchActions()
        fetchAreas()
        fetchUsers()
    }
    
    func fetchUsers(){
        usersController.fetchUsers()
        fillAvatarsList()
    }
    
    //utlility function that i quite importat -> it provides data type of MKCoordinateRegion used by map view to center map on current action
    func getInitialMapPosition() -> MKCoordinateRegion? {
        let currentActionData = actionDataController.getActionCoords(id: currentAction)
        var region = MKCoordinateRegion()
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(
            latitude: currentActionData.latitude,
            longitude: currentActionData.longitude),
                                    latitudinalMeters: 2*currentActionData.radius,
                                    longitudinalMeters: 2*currentActionData.radius)
        return region
    }
    
    //method responsible for fetching info about current user own areas -> fullfill user story
    func getMyAreas(){
        DispatchQueue.main.async {
            self.loadingStateMyAreas = .loading
        }
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/users/my_areas")!
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
                    self.loadingStateMyAreas = .failed
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any]
                if let areas = json?["areas"] {
                    DispatchQueue.main.async {
                        //we save received areas ids in local myAreas varaible
                        self.myAreas = areas as! [Int]
                        self.defaults.set(areas as! [Int], forKey: "myAreas")
                        self.loadingStateMyAreas = .loaded
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.loadingStateMyAreas = .failed
                }
                return
            }
        }
        task.resume()
    }
    
    //cached points SECTION
    
    func trySending(body: TemporaryPoint) -> AddingPointResult{
        DispatchQueue.main.async {
            self.loadingStateCache = .loading
        }
        let result = cachePointDataController.sendData(body: body)
        if result.0 == UpdateResult.success{
            actionDataController.addPointToAction(actionId: Int(body.action), pointData: result.1)
            actionDataController.saveImagetoPoint(pointId: result.1.id, data: body.blob)
            cachePointDataController.deletePoint(uuid: body.uuid)
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.emptyCache()
            }
            
            DispatchQueue.main.async {
                self.loadingStateCache = .loaded
            }
            return .uploaded
        }
        else {
            cachePointDataController.storePointToCache(point: body)
            DispatchQueue.main.async {
                self.loadingStateCache = .failed
            }
            return .cached
        }
    }
    
    func emptyCache() {
        let points: [TemporaryPoint] = cachePointDataController.getAllPoints()
        
        points.forEach{
            let result = cachePointDataController.sendData(body: $0)
            if (result.0 == UpdateResult.success){
                actionDataController.addPointToAction(actionId: $0.action, pointData: result.1)
                actionDataController.saveImagetoPoint(pointId: result.1.id, data: $0.blob)
                cachePointDataController.deletePoint(uuid: $0.uuid)
            }
        }
    }
    
    func joinAction(action: Int){
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/actions/" + String(action) + "/join")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
        }
        task.resume()
    }
    
    func leaveAction(){
        let url = URL(string: defaults.string(forKey: "ipAddress")! + "/actions/leave")!
        var request = URLRequest(url: url)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
        }
        task.resume()
    }
    
}
