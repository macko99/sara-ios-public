//
//  Extensions.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//

import Foundation
import SwiftUI
import MapKit

extension Array where Element == StoredPath {
    func toLocation() -> [CLLocationCoordinate2D] {
        var newArray = [CLLocationCoordinate2D]()
        for item in self{
            newArray.append(CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude))
        }
        return newArray
    }
}

extension String {
    var isInt: Bool {
        return Int(self) != nil
    }
}

extension Int {
    var toDateString: String {
        let dateFromInt = Date(timeIntervalSince1970: Double(self))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("E, d MMM yyyy HH:mm:ss")
        return dateFormatter.string(from: dateFromInt)
    }
    var toDateStringShort: String {
        let dateFromInt = Date(timeIntervalSince1970: Double(self))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("d.MMM HH:mm")
        return dateFormatter.string(from: dateFromInt)
    }
    var toDateStringVeryShort: String {
        let dateFromInt = Date(timeIntervalSince1970: Double(self))
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        dateFormatter.setLocalizedDateFormatFromTemplate("HH:mm")
        return dateFormatter.string(from: dateFromInt)
    }
}

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension StoredAction {
    var toAction: Action {
        let newAction = Action(description: self.descriptionText ?? "",
                               id: Int(self.id),
                               is_active: self.isActive,
                               latitude: self.latitude,
                               longitude: self.longitude,
                               name: self.name ?? "",
                               radius: self.radius,
                               start_time: Int(self.startTime))
        return newAction
    }
}

extension Array where Element == StoredArea {
    func toSimpleArea() -> [SimpleArea] {
        var newArray = [SimpleArea]()
        for item in self{
            newArray.append(SimpleArea(area_id: Int(item.id), name: item.name ?? ""))
        }
        return newArray
    }
}

extension Array where Element == StoredCoordinate {
    func toCoordinates() -> [Coordinates] {
        var newArray = [Coordinates]()
        for item in self{
            newArray.append(Coordinates(latitude: item.latitude,
                                        longitude: item.longitude,
                                        id: Int(item.id),
                                        order: Int(item.order)))
        }
        return newArray
    }
}

extension StoredUser {
    var toUser: User {
        let newUser = User(
            firstName: self.firstName!,
            lastName: self.lastName!,
            id: self.id!,
            phone:self.phone!,
            color: self.color!
        )
        return newUser
    }
}

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

extension User {
    static var dummyUser: User {
        return User(firstName: "Unknown", lastName: "Unknown", id: "Unknown", phone: "Unknown", color: "#ff8000")
    }
    var wasNotFound: Bool{
        return self.firstName == "Unknown" && self.lastName == "Unknown" && self.phone == "Unknown"
    }
}

extension Data {
    var isEmpty: Bool{
        return String(data: self, encoding: .utf8) == "empty"
    }
    var isLoaded: Bool{
        return String(data: self, encoding: .utf8) == "notLoaded"
    }
    static var empty = "empty".data(using: .utf8)!
    static var notLoaded = "notLoaded".data(using: .utf8)!
}

extension CustomPoint {
    static var example: CustomPoint {
        let point = CustomPoint(latitude: 0,
                                longitude: 0,
                                id: 0,
                                uuid: "",
                                name: "",
                                description: "",
                                time: 0,
                                ext: "",
                                userID: "",
                                kind: 0)
        return point
    }
    var isEmpty: Bool{
        return self.uuid == ""
    }
}

extension BinaryFloatingPoint {
    var dms: (degrees: Int, minutes: Int, seconds: Int) {
        var seconds = Int(self * 3600)
        let degrees = seconds / 3600
        seconds = abs(seconds % 3600)
        return (degrees, seconds / 60, seconds % 60)
    }
}

extension Double {
    var dms: (degrees: Int, minutes: Int, seconds: Int) {
        var seconds = Int(self * 3600)
        let degrees = seconds / 3600
        seconds = abs(seconds % 3600)
        return (degrees, seconds / 60, seconds % 60)
    }
    var latitudeDegree: String {
        let (degrees, minutes, seconds) = self.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "N" : "S")
    }
    var longitudeDegree: String {
        let (degrees, minutes, seconds) = self.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "E" : "W")
    }
}

extension CLLocationCoordinate2D {
    var locationInDegrees: String { latitudeDegree + "\n" + longitudeDegree }
    var locationInDegreesInline: String { latitudeDegree + " " + longitudeDegree }
    var latitudeDegree: String {
        let (degrees, minutes, seconds) = latitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "N" : "S")
    }
    var longitudeDegree: String {
        let (degrees, minutes, seconds) = longitude.dms
        return String(format: "%d°%d'%d\"%@", abs(degrees), minutes, seconds, degrees >= 0 ? "E" : "W")
    }
}


extension CachedPoint {
    var toTemporaryPoint: TemporaryPoint {
        let newCustom = TemporaryPoint(
            uuid: self.uuid!,
            descriptionText: self.descriptionText!,
            timestamp: Int(self.timestamp),
            latitude: self.latitude,
            longitude: self.longitude,
            blob: self.blob!,
            action: Int(self.action),
            kind: Int(self.kind),
            type: self.type!,
            name: self.name!)
        return newCustom
    }
}

extension Array where Element == CachedPoint {
    func toTemporaryPoints() -> [TemporaryPoint] {
        var newArray = [TemporaryPoint]()
        for item in self{
            newArray.append(item.toTemporaryPoint)
        }
        return newArray
    }
}

extension TemporaryPoint {
    var toBasicCustomPoint: CustomPoint {
        let newCustom = CustomPoint(
            latitude: self.latitude,
            longitude: self.longitude,
            id: -1,
            uuid: self.uuid,
            name: self.name,
            description: self.descriptionText,
            time: Int(self.timestamp),
            ext: self.type,
            userID: "",
            kind: Int(self.kind))
        return newCustom
    }
}

extension View {
    func endTextEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

//extension to get data from system
extension UIApplication {
    struct Constants {
        static let CFBundleShortVersionString = "CFBundleShortVersionString"
    }
    class func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: Constants.CFBundleShortVersionString) as! String
    }
    
    class func appBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }
    
    class func versionBuild() -> String {
        let version = appVersion(), build = appBuild()
        
        return version == build ? "v\(version)" : "v\(version) build \(build)"
    }
}
