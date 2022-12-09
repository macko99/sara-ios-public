//
//  Structs.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 24/05/2021.
//

import Foundation

struct ActionsResponse: Codable {
    var actions: [Action]
}

struct UsersResponse: Codable {
    var users: [User]
}

struct AreasResponse: Codable {
    var areas: [Area]
}

struct PointsResponse: Codable {
    var resources: [CustomPoint]
}

struct Action: Codable, Identifiable, Hashable {
    var description: String
    var id: Int
    var is_active: Bool
    var latitude: Double
    var longitude: Double
    var name: String
    var radius: Double
    var start_time: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ActionCoords: Codable{
    var latitude: Double
    var longitude: Double
    var radius: Double
    
    init() {
        latitude = 0
        longitude = 0
        radius = 0
    }
}

struct TemporaryPoint: Codable {
    var uuid: String
    var descriptionText: String
    var timestamp: Int
    var latitude: Double
    var longitude: Double
    var blob: Data
    var action: Int
    var kind: Int
    var type: String
    var name: String
}

struct Area: Codable {
    var area_id: Int
    var name: String
    var coordinates: [Coordinates]
}

struct SimpleArea: Codable {
    var area_id: Int
    var name: String
}

struct AreaUID: Hashable {
    var name: String
    var isMine: Bool
    var id: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

struct Coordinates: Codable {
    var latitude: Double
    var longitude: Double
    var id: Int
    var order: Int
    
}

struct CustomPoint: Codable {
    var latitude: Double
    var longitude: Double
    var id: Int
    var uuid: String
    var name: String
    var description: String
    var time: Int
    var ext: String
    var userID: String
    var kind: Int
}

struct User: Codable {
    var firstName: String
    var lastName: String
    var id: String
    var phone: String
    var color: String
}
