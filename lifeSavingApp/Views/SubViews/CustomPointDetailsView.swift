//
//  view to display point details, all-in-one solution resposible for getting all neccessary data from device memeory as well as calling http requsts to fetch images blobs from server and then save it to dev mem
//
//  CustomPointDetailsView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 16/05/2021.
//

import SwiftUI
import MapKit

struct CustomPointDetailsView: View {
    
    @EnvironmentObject var actionListController: ActionListController
    @ObservedObject var placemark: CustomAnnotation
    let defaults = UserDefaults.standard
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var loadingState = LoadingState.loading
    @State private var userData = User.dummyUser
    @State private var imageSource = ImageSource.notLoaded
    @State private var foundUser = false
    @State private var decodedImage = Image(systemName: "questionmark.square.fill")
    @State private var showImageViewer: Bool = false
    
    //geting user data from device memory, user that made this annotation
    func getUserData() {
        self.userData = actionListController.usersController.userDataController.getUser(id: placemark.user!)
        if(!self.userData.wasNotFound){
            self.foundUser = true
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack(alignment: .leading, spacing: 15){
                    HStack(){
                        Spacer()
                        Text(placemark.title ?? "No name provided")
                            .font(.title2)
                        Spacer()
                    }.padding([.bottom, .top], 15)
                    Group{
                        VStack(alignment: .leading){
                            Text("Description:").font(.headline).padding(.bottom, 5)
                            Text(placemark.descriptionText ?? "Empty")
                        }
                        Divider()
                        HStack{
                            Text("Time: ").font(.headline)
                            Spacer()
                            Text(placemark.time!.toDateString)
                        }
                        VStack{
                            HStack{
                                Text("Location: ").font(.headline)
                                Spacer()
                                Text(String(placemark.coordinate.latitude.rounded(toPlaces: 4))
                                     + "\n" +
                                     String(placemark.coordinate.longitude.rounded(toPlaces: 4)))
                                Text(String(placemark.coordinate.locationInDegrees))
                            }.padding(.bottom, 5)
                            Button(action: {
                                let coordinate = CLLocationCoordinate2DMake(placemark.coordinate.latitude, placemark.coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
                                mapItem.name = "Point " + (placemark.title ?? "")
                                mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking])
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "figure.walk")
                                    Text("Get directions")
                                        .font(.caption)
                                }
                            }
                        }
                        Divider()
                        HStack{
                            Text("User: ").font(.headline)
                            Spacer()
                            if(foundUser){
                                Text(userData.firstName + " " + userData.lastName)
                            }
                            else{
                                Text("Unknown")
                            }
                        }
                        HStack{
                            Text("Phone number:").font(.headline)
                            Spacer()
                            if(foundUser){
                                Button(action: {
                                    let number = userData.phone
                                    let formattedString = "tel://" + number
                                    guard let url = URL(string: formattedString) else { return }
                                    UIApplication.shared.open(url)
                                }) {
                                    HStack{
                                        Image(systemName: "phone.fill")
                                        Text(userData.phone)
                                    }
                                }
                            }
                            else{
                                Text("Unknown")
                            }
                        }
                        Divider()
                    }
                    VStack{
                        HStack{
                            Text("Media content").font(.headline).padding(.bottom, 10)
                            Spacer()
                        }
                        if loadingState == .loaded {
                            Button(action:{
                                showImageViewer.toggle()
                            }){
                                decodedImage
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        else if loadingState == .empty || loadingState == .loading{
                            Text(loadingState.description)
                        }
                        else {
                            HStack{
                                Text("Please try again")
                                Button(action: {
                                    fetchImage()
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                        }
                    }
                    Spacer()
                }
                .padding([.leading, .trailing], 20)
                .navigationBarTitle("Point details")
                .navigationBarItems(trailing: Button("Close") {
                    self.presentationMode.wrappedValue.dismiss()
                })
                //on appear of this view it tries to fetch user data and fetch image to display
                .onAppear(perform: {
                    getUserData()
                    fetchImage() //MARK: breaks preview
                })
            }
        }
        //responsible for showing image on full screen -> shity, may be good idea to change MARK: change
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(ImageViewer(image: $decodedImage, viewerShown: self.$showImageViewer, caption: Text((placemark.title ?? ""))))
    }
    
    //getting image
    func fetchImage(){
        //we try to find image in local storage by its uuid
        let loaclRessource = actionListController.actionDataController.getImageForPoint(imageUUID: placemark.resourceUID!)
        //if we found it -> ready to display
        if (loaclRessource != nil && loaclRessource != Data.notLoaded) {
            if(loaclRessource!.isEmpty){
                self.imageSource = .fromMemory
                self.loadingState = .empty
                return
            }
            let uiImage = UIImage(data: loaclRessource!)!
            decodedImage = Image(uiImage: uiImage)
            self.imageSource = .fromMemory
            self.loadingState = .loaded
            return
        }
        
        //if we dont have this image in phones memory its time to fetch it from server
        var url = URLComponents(string: defaults.string(forKey: "ipAddress")!)!
        url.path = "/resources/blob"
        url.queryItems = [
            URLQueryItem(name: "uuid", value: placemark.resourceUID!)
        ]
        
        var request = URLRequest(url: url.url!)
        
        request.setValue(
            defaults.string(forKey: "authToken"),
            forHTTPHeaderField: "Authorization"
        )
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if let data = data {
                //images are received as base64 string -> decode and ready to display
                if let decodedData = Data(base64Encoded: data, options: .ignoreUnknownCharacters) {
                    //no content for this point
                    if(decodedData.count == 0){
                        self.loadingState = .empty
                        self.imageSource = .fromServer
                        //saving "no content" to memory
                        saveImage(data: Data.empty)
                        return
                    }
                    let uiImage = UIImage(data: decodedData)!
                    decodedImage = Image(uiImage: uiImage)
                    //save image in device memory for future access, saving data and enabling offline usage
                    saveImage(data: decodedData)
                    self.loadingState = .loaded
                    self.imageSource = .fromServer
                    return
                }
            }
            self.loadingState = .failed
        }
        task.resume()
    }
    
    //save image in dev mem
    func saveImage(data: Data){
        actionListController.actionDataController.saveImagetoPoint(pointId: placemark.id!, data: data)
    }
    
}

struct CustomPointDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPointDetailsView(placemark: CustomAnnotation.example)
            .environmentObject(ActionListController.example)
    }
}
