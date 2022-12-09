//
//  class for holding custom annotation type (points displayed on map with all its data)
//
//  CustomAnnotation.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 16/05/2021.
//

//MARK: colors of pins are not working in ios 15+

import MapKit
import SwiftUI

enum AnnotationType: Int {
    case bellAnnotation = 0
    case warningAnnotation = 1
    case infoAnnotation = 2
    case flagAnnotation = 3
    case envelopeAnnotation = 4
    case pinAnnotation = 5
    case starAnnotation = 6
    
    func image() -> UIImage {
        switch self {
        case .bellAnnotation:
            return UIImage(systemName: "bell.circle.fill")! //􀋜
        case .warningAnnotation:
            return UIImage(systemName: "exclamationmark.triangle.fill")! //􀇿
        case .infoAnnotation:
            return UIImage(systemName: "info.circle.fill")! //􀅵
        case .flagAnnotation:
            return UIImage(systemName: "flag.circle.fill")! //􀋌
        case .envelopeAnnotation:
            return UIImage(systemName: "envelope.circle.fill")! //􀍘
        case .pinAnnotation:
            return UIImage(systemName: "pin.circle.fill")! //􀒵
        case .starAnnotation:
            return UIImage(systemName: "star.circle.fill")! //􀋆
        }
    }
}


class CustomAnnotation: NSObject, MKAnnotation {
    
    let coordinate: CLLocationCoordinate2D
    let type: AnnotationType
    var title: String?
    var descriptionText: String?
    let time: Int?
    let user: String?
    let id: Int?
    let resourceUID: String?
    
    init(coordinate: CLLocationCoordinate2D,
         name: String,
         descriptionText: String,
         time: Int,
         type: AnnotationType,
         user: String,
         id: Int,
         resourceUID: String) {
        self.coordinate = coordinate
        self.title = name
        self.descriptionText = descriptionText
        self.type = type
        self.time = time
        self.user = user
        self.id = id
        self.resourceUID = resourceUID
    }
}


extension CustomAnnotation: ObservableObject {
    public var wrappedTitle: String {
        get {
            self.title ?? "Unknown"
        }
        set {
            title = newValue
        }
    }
    
    public var wrappedSubtitle: String {
        get {
            self.descriptionText ?? "Unknown"
        }
        set {
            descriptionText = newValue
        }
    }
    
}

class CustomAnnotationView: MKAnnotationView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        guard let customAnnotation = self.annotation as? CustomAnnotation else { return }
        
        image = customAnnotation.type.image()
            .withTintColor(UIColor.red, renderingMode: UIImage.RenderingMode.alwaysTemplate)
    }
}
