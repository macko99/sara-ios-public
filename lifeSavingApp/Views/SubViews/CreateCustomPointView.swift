//
//  view to display point details, all-in-one solution resposible for getting all neccessary data from device memeory as well as calling http requsts to fetch images blobs from server and then save it to dev mem
//
//  CustomPointDetailsView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 16/05/2021.
//


var showingPopupMap = false

import SwiftUI
import MapKit

struct CreateCustomPointView: View {
    
    @EnvironmentObject var actionListController: ActionListController
    var uuid: String
    var timestamp: Int
    var latitude: Double
    var longitude: Double
    var action: Int
    var kind: Int
    var type: String
    
    @ObservedObject private var name = TextLimiter(limit: 60)
    @ObservedObject private var description = TextLimiter(limit: 250)
    @State private var blob = Data.empty
    
    let defaults = UserDefaults.standard
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showAlert: Bool = false
    @State private var activeAlert: ActiveCreateAlert = .cancel
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var image: Image?
    
    init(uuid: String, timestamp: Int, latitude: Double, longitude: Double, action: Int, kind: Int, type: String) {
        self.uuid = uuid
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.action = action
        self.kind = kind
        self.type = type
        
        UITextView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(alignment: .leading, spacing: 15){
                    Group{
                        Divider()
                            .padding(.top, 15)
                        HStack{
                            if(actionListController.loadingStateCache == .loading ||
                               actionListController.loadingStateCache == .loading){
                                Text("Time: ").font(.headline)
                                    .onDisappear(perform: {
                                        showingPopupMap = false
                                    })
                            }
                            else{
                                Text("Time: ").font(.headline)
                            }
                            Spacer()
                            Text(timestamp.toDateString)
                        }
                        VStack{
                            HStack{
                                Text("Location: ").font(.headline)
                                Spacer()
                                Text(String(latitude.rounded(toPlaces: 4))
                                     + "\n" +
                                     String(longitude.rounded(toPlaces: 4)))
                                Text(latitude.latitudeDegree
                                     + "\n" +
                                     longitude.longitudeDegree)
                            }
                        }
                        Divider()
                    }
                    .onTapGesture {
                        self.endTextEditing()
                    }
                    VStack{
                        HStack{
                            Text("Name:").font(.headline)
                                .padding(.bottom, 10)
                                .onTapGesture {
                                    self.endTextEditing()
                                }
                            Spacer()
                        }
                        ZStack(alignment: .leading) {
                            if name.value.isEmpty { Text("name").foregroundColor(.gray) }
                            TextField("", text: $name.value)
                        }.foregroundColor(.black)
                            .padding()
                            .background(!name.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                            .cornerRadius(20.0)
                            .shadow(radius: 5.0, x: 2, y: 1)
                        if(name.hasReachedLimit){
                            Text("Exceeded character limit.")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding([.top, .bottom], -5)
                                .padding([.trailing, .leading], 20)
                        }
                    }.padding(.bottom, 5)
                    VStack{
                        Button(action: {self.endTextEditing()}){
                            HStack{
                                Text("Description:").font(.headline)
                                    .foregroundColor(Color("Text"))
                                    .padding(.bottom, 10)
                                Spacer()
                            }
                        }
                        ZStack{
                            if description.value.isEmpty { Text("description").foregroundColor(.gray).zIndex(1) }
                            TextEditor(text: $description.value)
                        }.foregroundColor(.black)
                            .padding()
                            .frame(minHeight: 150, maxHeight: 250)
                            .background(!description.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                            .cornerRadius(20.0)
                            .shadow(radius: 5.0, x: 2, y: 1)
                        if(description.hasReachedLimit){
                            Text("Exceeded character limit.")
                                .font(.footnote)
                                .foregroundColor(.red)
                                .padding([.top, .bottom], -5)
                                .padding([.trailing, .leading], 20)
                        }
                        
                    }
                    Divider().padding(.top, 10)
                    VStack(alignment: .center){
                        HStack{
                            Text("Media content:").font(.headline)
                            Spacer()
                        }
                        HStack{
                            Text("You can attach an image to this point below.").font(.caption)
                                .padding(.bottom, 10)
                            Spacer()
                        }
                        if (inputImage != nil), let image = image{
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 400)
                            
                            HStack{
                                Button(action: {
                                    self.showingImagePicker = true
                                })
                                {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Change selection").font(.subheadline)
                                }
                                Button(action: {
                                    inputImage = nil
                                })
                                {
                                    Image(systemName: "trash")
                                    Text("Remove selection").font(.subheadline)
                                }
                            }
                        } else {
                            HStack{
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Tap to select a picture")
                            }
                            .font(.subheadline)
                            .onTapGesture {
                                self.showingImagePicker = true
                            }
                        }
                    }.padding(.bottom, 20)
                    HStack{
                        Spacer()
                        Button(action: {
                            showingPopupMap = true
                            let item = TemporaryPoint(uuid: uuid,
                                                      descriptionText: description.value,
                                                      timestamp: timestamp,
                                                      latitude: latitude,
                                                      longitude: longitude,
                                                      blob: inputImage?.jpegData(compressionQuality: 0.1) ?? Data.empty,
                                                      action: action,
                                                      kind: kind,
                                                      type: type,
                                                      name: name.value)
                            DispatchQueue.global(qos: .userInteractive).async {
                                self.activeAlert = actionListController.trySending(body: item).toActiveCreateAlert
                                DispatchQueue.main.async {
                                    self.showAlert = true
                                }
                            }
                            
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add point")
                                    .fontWeight(.semibold)
                                    .font(.body)
                            }
                            .padding()
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.red, .purple]),
                                               startPoint: .leading,
                                               endPoint: .trailing))
                            .cornerRadius(30)
                            .shadow(radius: 5.0)
                        }
                        Spacer()
                    }.padding(.bottom, 30)
                    
                }.padding([.leading, .trailing], 20)
                    .navigationBarTitle("Create new point")
                    .navigationBarItems(trailing: Button("Cancel") {
                        self.showAlert = true
                        self.activeAlert = .cancel
                    })
                    .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                        ImagePicker(image: self.$inputImage)
                    }
                    .alert(isPresented: $showAlert) {
                        switch activeAlert {
                        case .cancel:
                            return Alert(title: Text("Please confirm"),
                                         message: Text("Do you want to cancel?"),
                                         primaryButton: .default(Text("Yes")){
                                self.presentationMode.wrappedValue.dismiss()
                            }, secondaryButton: .default(Text("Cancel")){})
                        case .uploaded:
                            return Alert(title: Text("Success"),
                                         message: Text("Data was successfully uploaded!"),
                                         dismissButton: .default(Text("Got it!"))
                                         {
                                self.presentationMode.wrappedValue.dismiss()
                            })
                        case .cached:
                            return Alert(title: Text("Network failed"),
                                         message: Text("Do not worry, we will try again later automatiacally."),
                                         dismissButton: .default(Text("Got it!"))
                                         {
                                self.presentationMode.wrappedValue.dismiss()
                            })
                        case .failed:
                            return Alert(title: Text("Something went wrong"),
                                         message: Text("Sorry, something went wrong... Try again later"),
                                         dismissButton: .default(Text("Close")){
                                self.presentationMode.wrappedValue.dismiss()
                            })
                        }
                    }
                
            }
        }.disabled(showingPopupMap)
            .popup(isPresented: showingPopupMap, content: {
                AnimatedImageView()
            })
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
    }
}

struct CreateCustomPointView_Preview: PreviewProvider {
    static var previews: some View {
        CreateCustomPointView(
            uuid: UUID().uuidString,
            timestamp: Int(Date().timeIntervalSince1970),
            latitude: 20,
            longitude: 20,
            action: 1,
            kind: 0,
            type: "jpeg")
            .environmentObject(ActionListController.example)
    }
}
