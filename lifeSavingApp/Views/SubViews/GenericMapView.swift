//
//  GenericMapView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 10/10/2021.
//

import SwiftUI
import MapKit

struct GenericMapView: UIViewRepresentable {
    
    @Binding var showingCustomPlaceDetails: Bool
    @Binding var centerLocation: String
    @Binding var shapesNamesAnnotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.layoutMargins = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 7)
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.showsUserLocation = true
    }
    
    //coordinator of map view
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GenericMapView
        
        init(_ parent: GenericMapView) {
            self.parent = parent
        }
        
        //called when visibale region of map has changed
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            self.parent.centerLocation = mapView.centerCoordinate.locationInDegreesInline
        }
        
        //called when rendering/displaying annotations
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            //annotation of type MKUserLocation -> choose to show as MKUserLocationView
            if annotation is MKUserLocation{
                let annotationView = MKUserLocationView(annotation: annotation, reuseIdentifier: "Location")
                return annotationView
            }
            if annotation is MKPointAnnotation{
                let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "Name")
                annotationView.glyphText = NSLocalizedString("Area", comment: "")
                annotationView.glyphTintColor = UIColor(Color("Text"))
                annotationView.markerTintColor = UIColor(Color("Text").opacity(0.3))
                parent.shapesNamesAnnotations.append(annotation as! MKPointAnnotation)
                return annotationView
            }
            //any other annotation choose to show as CustomAnnotationView (our own view) -> //or MKMarkerAnnotationView //or MKPinAnnotationView MARK: decide
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Custom")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }
        
        //called when tapping annotations
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            //annotation was tappe -> and it is our custom annotation save selected to selectedCustomPlace
            if let placemark = view.annotation as? CustomAnnotation {
                selectedCustomPlace = placemark
                parent.showingCustomPlaceDetails = true
                return
            }
        }
        
        //called when displaying/rendering shapes (MKOverlay)
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            //if it is of type MKPolyline - so line - use system MKPolylineRenderer to display it, set random color randomColor,
            //save this color to routeColor, save true to isRouteShown and choose new color (randomColor)
            if overlay is MKPolyline {
                let lineView = MKPolylineRenderer(overlay: overlay)
                let randomColor = UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1)
                lineView.strokeColor = randomColor
                return lineView
            }
            //if it is of type MKPolygon - so shape - use MKPolygonRenderer to display it, set different color for my/other shapes and
            //save color to shapeColor and set true in isShapeShown
            else if overlay is MKPolygon {
                let polygonView = MKPolygonRenderer(overlay: overlay)
                polygonView.strokeColor = overlay.subtitle == "my" ? .green : .magenta
                polygonView.fillColor = UIColor.yellow.withAlphaComponent(0.2)
                polygonView.lineWidth = 2
                return polygonView
            }
            
            return MKOverlayRenderer()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
