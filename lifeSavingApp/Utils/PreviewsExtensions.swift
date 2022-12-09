//
//  PreviewsExtensions.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 24/05/2021.
//

import Foundation
import MapKit

extension LoginController {
    static var example: LoginController {
        let newController = LoginController()
        newController.pushInterval = 60
        newController.observationWidth = 30
        return newController
    }
}

extension UserLocationController {
    static var example: UserLocationController {
        let newController = UserLocationController()
        return newController
    }
}

extension Action {
    static var example: Action {
        let action = Action(description: "test ewhcoicwj pefjpoef eekc[pwfei0 e0dwi0d w0id[iq0wd d0id0eif qw0di0id0w000 w000oo oeoeoe e0e0e0",
                            id: 1,
                            is_active: true,
                            latitude: 33.33,
                            longitude: 33.212,
                            name: "nazwa 123",
                            radius: 233,
                            start_time: 1634151815)
        return action
    }
    static var example2: Action {
        let action = Action(description: "test ewhcoicwj pefjpoef eekc[pwfei0 e0dwi0d w0id[iq0wd d0id0eif qw0di0id0w000 w000oo oeoeoe e0e0e0",
                            id: 1,
                            is_active: false,
                            latitude: 33.33,
                            longitude: 33.212,
                            name: "nazwa 123",
                            radius: 233,
                            start_time: 1634151815)
        return action
    }
}

extension ActionListController {
    static var example: ActionListController {
        let newController = ActionListController()
        newController.actions = [Action.example, Action.example2]
        return newController
    }
}

extension UserDataPatchController {
    static var example: UserDataPatchController {
        let newController = UserDataPatchController()
        return newController
    }
}

extension MKPointAnnotation {
    static var example: MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.title = "Test title"
        annotation.subtitle = "Test subtitle"
        annotation.coordinate = CLLocationCoordinate2D(latitude: 51.02, longitude: 19.9012)
        return annotation
    }
}

extension CustomAnnotation {
    static var example: CustomAnnotation {
        let annotation = CustomAnnotation(coordinate: CLLocationCoordinate2D(latitude: 51.02, longitude: 19.9012),
                                          name: "Test name",
                                          descriptionText: "Test desc.",
                                          time: 1634151815,
                                          type: .warningAnnotation,
                                          user: "eferfr-334",
                                          id: 1,
                                          resourceUID: "1")
        return annotation
    }
}

extension MKCoordinateRegion {
    static var example: MKCoordinateRegion {
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: 50.02, longitude: 19.9012)
        region.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        return region
    }
}
