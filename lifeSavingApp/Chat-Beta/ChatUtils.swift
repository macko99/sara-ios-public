//
//  ChatUtils.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 04/11/2021.
//

import Foundation
import TwilioConversationsClient
import SwiftUI

protocol QuickstartConversationsManagerDelegate: AnyObject {
    func reloadMessages()
    func receivedNewMessage()
    func displayStatusMessage(_ statusMessage:String)
    func displayErrorMessage(_ errorMessage:String)
}

extension TCHMessage : Identifiable {
    
}

struct Avatar: Codable {
    var color: String
    var avatar: String
}

enum ChatAuthorizedStatus {
    case notActive, authorized, failed, loading, notAvailable
    
    var description : String {
        switch self {
        case .notActive: return NSLocalizedString("notActive", comment: "")
        case .authorized: return NSLocalizedString("authorized", comment: "")
        case .failed: return NSLocalizedString("failed", comment: "")
        case .loading: return NSLocalizedString("loading", comment: "")
        case .notAvailable: return NSLocalizedString("notAvailable", comment: "")
        }
    }
}

struct ChatUtils {
    
    static func retrieveToken(id: String, completion: @escaping (String?, String?, Error?) -> Void) {
        
        let url = URL(string: UserDefaults.standard.string(forKey: "ipAddress")! + "/authorize/twilio?identity=" + id)!
        var request = URLRequest(url: url)
        request.setValue(
            UserDefaults.standard.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        let task = session.dataTask(with: request, completionHandler: { (data, _, error) in
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let tokenData = json as? [String: String] {
                        let token = tokenData["token"]
                        let identity = tokenData["identity"]
                        completion(token, identity, error)
                    }
                    else {
                        completion(nil, nil, nil)
                    }
                }
                catch let error as NSError {
                    completion(nil, nil, error)
                }
            }
            else {
                completion(nil, nil, error)
            }
        })
        task.resume()
    }
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    a = 1.0

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}

