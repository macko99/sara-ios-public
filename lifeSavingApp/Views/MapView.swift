//
//  MapView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 12/05/2021.
//

import SwiftUI
import MapKit

var selectedCustomPlace: CustomAnnotation?

struct MapView: View {
    //incjected controllers
    @EnvironmentObject var actionListController: ActionListController
    @EnvironmentObject var userLocationController: UserLocationController
    
    @State private var showingCustomPlaceDetails = false
    @State private var showingCreateCustomPlace = false
    
    //indicates if things on map are showing
    @State private var showingOtherBoundaries = false
    @State private var showingMyBoundaries = false
    @State private var showingMapPins = false
    @State private var shwoingMapRoutes = false
    @State private var showingAreasNames = false
    
    @State private var currentMapType :MKMapType = .standard
    @State private var trackingHeading = 0
    @State private var centerLocation = ""
    
    @State var shapesNamesAnnotations = [MKPointAnnotation]()
    
    //data structers for items put on map
    @State private var routesOnMap = [MKPolyline]()
    @State private var shapesOnMap = [MKPolygon]()
    @State private var myShapesOnMap = [MKPolygon]()
    
    var body: some View {
        ZStack{
            VStack{
                Text(centerLocation)
                    .padding(.top, 60)
                Spacer()
            }
            .zIndex(1)
            
            GenericMapView(
                showingCustomPlaceDetails: $showingCustomPlaceDetails,
                centerLocation: $centerLocation,
                shapesNamesAnnotations: $shapesNamesAnnotations
            )
                .edgesIgnoringSafeArea(.all)
            
            Circle()
                .strokeBorder(Color.blue, lineWidth: 1)
                .background(Circle()
                                .foregroundColor(Color.blue)
                                .opacity(0.2))
                .frame(width: 20, height: 20, alignment: .center)
                .padding(.trailing, 7)
            
            VStack{
                HStack{
                    Spacer()
                    Button(action: {
                        centerUserLocation()
                    }){
                        Image(systemName: trackingHeading == 0 ? "location" :
                                trackingHeading == 1 ? "location.north.fill" :
                                "location.north.line.fill")
                            .frame(width: 15, height: 15)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .font(.body)
                    .clipShape(Rectangle())
                    .cornerRadius(radius: 15, corners: [.topLeft, .topRight])
                    .padding(.trailing, 10)
                }
                .padding(.bottom, -8)
                HStack{
                    Spacer()
                    Rectangle()
                        .frame(width: 47, height: 1)
                        .foregroundColor(Color.gray)
                        .padding(.trailing, 10)
                }
                HStack{
                    Spacer()
                    Button(action: {
                        centerAction()
                    }){
                        Image(systemName: "viewfinder")
                            .frame(width: 15, height: 15)
                    }
                    .padding()
                    .foregroundColor(actionListController.actionIsSet ? .white : .gray)
                    .disabled(!actionListController.actionIsSet)
                    .background(Color.black.opacity(0.7))
                    .font(.body)
                    .clipShape(Rectangle())
                    .padding(.trailing, 10)
                }
                .padding([.top, .bottom], -8)
                HStack{
                    Spacer()
                    Rectangle()
                        .frame(width: 47, height: 1)
                        .foregroundColor(Color.gray)
                        .padding(.trailing, 10)
                }
                HStack{
                    Spacer()
                    Button(action: {
                        self.showingCreateCustomPlace = true
                        userLocationController.killLocationService()
                        actionListController.timer.invalidate()
                    }){
                        Image(systemName: "plus")
                            .frame(width: 15, height: 15)
                    }
                    .padding()
                    .foregroundColor(actionListController.actionIsSet ? .white : .gray)
                    .disabled(!actionListController.actionIsSet)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .font(.body)
                    .clipShape(Rectangle())
                    .cornerRadius(radius: 15, corners: [.bottomLeft, .bottomRight])
                    .padding(.trailing, 10)
                }
                .padding(.top, -8)
            }
            
            SlideOverCardView {
                VStack {
                    if(!actionListController.actionIsSet || actionListController.actionWasChanged){
                        HStack{
                            Text("Action is not set. To take full advantage of map view please join one of available actions first.")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding([.top, .bottom], -5)
                                .padding([.trailing, .leading], 20)
                        }.onAppear(perform: {
                            //so when we leave action -> remove items from map
                            self.showingMapPins = false
                            self.showingMyBoundaries = false
                            self.showingOtherBoundaries = false
                            self.shwoingMapRoutes = false
                            actionListController.actionWasChanged = false
                        })
                    }
                    else{
                        Spacer().frame(height: 25)
                    }
                    Group{
                        HStack{
                            Picker("", selection: $currentMapType) {
                                Text("Standard").tag(MKMapType.standard)
                                Text("Satellite").tag(MKMapType.satellite)
                                Text("Hybrid").tag(MKMapType.hybrid)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .font(.largeTitle)
                            .onChange(of: currentMapType) { value in
                                chnageMapType(type: currentMapType)
                            }
                        }.padding([.trailing, .leading], 20)
                        HStack{
                            Toggle("Show my areas", isOn: $showingMyBoundaries)
                                .disabled(!actionListController.actionIsSet)
                                .onChange(of: showingMyBoundaries) { value in
                                    self.toggleMyBoundaries()
                                }
                        }.padding([.trailing, .leading], 20)
                        Divider()
                        HStack{
                            Toggle("Show other areas", isOn: $showingOtherBoundaries)
                                .disabled(!actionListController.actionIsSet)
                                .onChange(of: showingOtherBoundaries) { value in
                                    self.toggleOtherBoundaries()
                                }
                        }.padding([.trailing, .leading], 20)
                        Divider()
                        HStack{
                            Toggle("Show areas names", isOn: $showingAreasNames)
                                .disabled(!actionListController.actionIsSet || !(showingMyBoundaries || showingOtherBoundaries))
                                .onChange(of: showingAreasNames) { value in
                                    self.addBoundariesNames()
                                }
                        }.padding([.trailing, .leading], 20)
                    }
                    Group{
                        Divider()
                        HStack{
                            Toggle("Show my routes", isOn: $shwoingMapRoutes)
                                .disabled(!actionListController.actionIsSet)
                                .onChange(of: shwoingMapRoutes) { value in
                                    self.toggleRoute()
                                }
                        }.padding([.trailing, .leading], 20)
                        Divider()
                        HStack{
                            Toggle("Show special points", isOn: $showingMapPins)
                                .disabled(!actionListController.actionIsSet)
                                .onChange(of: showingMapPins) { value in
                                    self.togglePins()
                                }
                        }.padding([.trailing, .leading], 20)
                        Divider()
                    }
                }
            }
            .onChange(of: actionListController.actionDataWasRefreshed){newValue in
                self.togglePins()
                self.toggleRoute()
            }
        }
        .onAppear(){
            if(actionListController.shouldBeActionInFocus && actionListController.actionIsSet){
                if let region = actionListController.getInitialMapPosition(){
                    mapView.setRegion(region, animated: true)
                }
                actionListController.shouldBeActionInFocus = false
            }
        }
        .sheet(isPresented: $showingCustomPlaceDetails) {
            if selectedCustomPlace != nil {
                CustomPointDetailsView(placemark: selectedCustomPlace!)
                    .environmentObject(actionListController)
            }
        }
        .sheet(isPresented: $showingCreateCustomPlace, onDismiss: {
            self.togglePins()
            userLocationController.resumeLocationServiceIfTurnOn()
            actionListController.startTimer()
        }) {
            CreateCustomPointView(uuid: UUID().uuidString,
                                  timestamp: Int(Date().timeIntervalSince1970),
                                  latitude: mapView.centerCoordinate.latitude,
                                  longitude: mapView.centerCoordinate.longitude,
                                  action: actionListController.currentAction,
                                  kind: AnnotationType.bellAnnotation.rawValue, //MARK: not used in app logic -> dummy example
                                  type: "jpeg").environmentObject(actionListController)
            
        }
    }
    
    //adding annotations/pins/points to map -> from device memory
    func addCustomPins() {
        actionListController.actionDataController.getActionPoints(actionId: actionListController.currentAction)
    }
    
    //button use to to center map on action center
    func centerAction() {
        if let region = actionListController.getInitialMapPosition(){
            mapView.setRegion(region, animated: true)
        }
    }
    
    func addBoundariesNames(){
        if( !showingMyBoundaries && !showingOtherBoundaries){
            showingAreasNames = false
        }
        mapView.removeAnnotations(shapesNamesAnnotations)
        if(showingAreasNames){
            for item in mapView.overlays{
                if(item.title != "path"){
                    let annotation = MKPointAnnotation()
                    annotation.title = item.title ?? "empty"
                    annotation.coordinate = item.coordinate
                    mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    //used by user location button
    func centerUserLocation() {
        mapView.setRegion(
            MKCoordinateRegion(center: mapView.userLocation.coordinate,
                               span: MKCoordinateSpan(
                                latitudeDelta: 0.05,
                                longitudeDelta: 0.05)),
            animated: true)
        mapView.userTrackingMode = mapView.userTrackingMode.rawValue == 0 ?
        MKUserTrackingMode.follow :
        mapView.userTrackingMode.rawValue == 1 ?
        MKUserTrackingMode.followWithHeading :
        MKUserTrackingMode.none
        trackingHeading = mapView.userTrackingMode.rawValue
    }
    
    //adding routes to map -> from device memory
    func addRoute() {
        var coords = [Int : [CLLocationCoordinate2D]]()
        do{
            coords = try userLocationController.locationDataController.getUserPath(action: actionListController.currentAction)
            for route in coords.keys{
                let newRoute = MKPolyline(coordinates: coords[route]!, count: coords[route]!.count)
                newRoute.title = "path"
                routesOnMap.append(newRoute)
                mapView.addOverlay(newRoute)
            }
        }
        catch{}
    }
    
    //adding shapes to map -> from device memory
    func addBoundaries(justMy: Bool) {
        var coords = [AreaUID : [CLLocationCoordinate2D]]()
        do{
            coords = try actionListController.getAllCoordinates(justMyAreas: justMy)
            for area in coords.keys{
                let newBoundary = MKPolygon(coordinates: coords[area]!, count: coords[area]!.count)
                newBoundary.title = area.name
                newBoundary.subtitle = justMy ? "my" : ""
                if(justMy) { myShapesOnMap.append(newBoundary) }
                else { shapesOnMap.append(newBoundary) }
                mapView.addOverlay(newBoundary)
            }
        }
        catch{}
    }
    
    func chnageMapType(type: MKMapType){
        mapView.mapType = type
        currentMapType = type
    }
    
    func toggleOtherBoundaries() {
        if (showingOtherBoundaries){
            addBoundaries(justMy: false)
        }
        else{
            mapView.removeOverlays(shapesOnMap)
            shapesOnMap.removeAll()
        }
        addBoundariesNames()
    }
    
    func toggleMyBoundaries() {
        if (showingMyBoundaries){
            addBoundaries(justMy: true)
        }
        else{
            mapView.removeOverlays(myShapesOnMap)
            myShapesOnMap.removeAll()
        }
        addBoundariesNames()
    }
    
    func toggleRoute() {
        mapView.removeOverlays(routesOnMap)
        routesOnMap.removeAll()
        if shwoingMapRoutes {
            addRoute()
        }
    }
    
    func togglePins() {
        mapView.removeAnnotations(mapView.annotations)
        addBoundariesNames()
        if showingMapPins {
            addCustomPins()
        }
    }
    
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView().environmentObject(ActionListController.example)
            .environmentObject(UserLocationController.example)
    }
}
