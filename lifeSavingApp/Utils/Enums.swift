//
//  Enums.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 24/05/2021.
//

import Foundation
import SwiftUI

enum LoadingState {
    case loading, loaded, failed, idle, empty
    
    var description : String {
        switch self {
        case .loading: return "Loding..."
        case .loaded: return "Loaded"
        case .failed: return "Faild"
        case .idle: return "Idle"
        case .empty: return "No media content"
        }
    }
}

enum WchichBoundary {
    case all, my
}

enum UpdateResult {
    case success, failed, usernameTaken, waiting
}

enum AddingPointResult {
    case uploaded, cached, failed
    
    var toActiveCreateAlert : ActiveCreateAlert {
        switch self {
        case .uploaded: return .uploaded
        case .cached: return .cached
        case .failed: return .failed
        }
    }
}

enum ActiveLoginAlert {
    case ip, cred
}

enum ActiveCreateAlert {
    case cancel, uploaded, cached, failed
}

enum ImageSource {
    case notLoaded, fromServer, fromMemory
    
    var description : String {
        switch self {
        case .notLoaded: return "Not loaded yet"
        case .fromServer: return "Loaded from server"
        case .fromMemory: return "Image saved locally"
        }
    }
}

enum ActiveActionListAlert {
    case leave, change, new
}

enum ActiveChangeUsernameAlert {
    case faild, success, taken, empty
}

enum LastState {
    case ok, error, network, unsend
}

enum CardPosition: CGFloat {
    case top
    case bottom
    
    var ValueForScreen: CGFloat {
        switch self {
        case .top:
            return UIDevice.current.userInterfaceIdiom == .pad ?
            0.70*UIScreen.screenHeight :
            UIScreen.screenHeight > 700 ?
            0.54*UIScreen.screenHeight :
            0.48*UIScreen.screenHeight
        case .bottom:
            return (UIDevice.current.userInterfaceIdiom == .pad || UIScreen.screenHeight < 700) ?
            max(0.9*UIScreen.screenHeight, UIScreen.screenHeight-70) :
            0.88*UIScreen.screenHeight
        }
    }
}

enum DragState {
    case inactive
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .inactive:
            return false
        case .dragging:
            return true
        }
    }
}
