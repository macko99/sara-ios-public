//
//  ActionDetailsView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 09/10/2021.
//

import SwiftUI
import MapKit

struct ActionDetailsView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let action: Action
    @Binding var showingAlert: Bool
    @Binding var currentAlert: ActiveActionListAlert
    @Binding var currentAction: Int
    @Binding var selectedAction: Action
    
    var body: some View {
        ScrollView{
            VStack{
                HStack{
                    VStack(alignment: .leading, spacing: 18){
                        HStack{
                            Spacer()
                            Text("Action details")
                                .font(.title2)
                                .padding(.bottom, 15)
                            Spacer()
                        }
                        Group{
                            HStack{
                                Text("Name:").font(.headline)
                                Spacer()
                                Text(action.name)
                            }
                            Divider()
                            HStack{
                                Text("Start time:").font(.headline)
                                Spacer()
                                Text(action.start_time.toDateString)
                            }
                            Divider()
                            VStack(alignment: .leading){
                                Text("Description:").font(.headline).padding(.bottom, 5)
                                Text(action.description)
                            }
                            Divider()
                            HStack{
                                Text("Is active now:").font(.headline)
                                Spacer()
                                Text(action.is_active == true ? "Yes" : "No")
                            }
                            Divider()
                        }
                        Group{
                            ZStack{
                                Map(coordinateRegion: .constant(
                                    MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: action.latitude, longitude:action.longitude),
                                                       latitudinalMeters: action.radius*2.3,
                                                       longitudinalMeters: action.radius*2.3)),
                                    interactionModes: [],
                                    showsUserLocation: true,
                                    userTrackingMode: .constant(.none))
                                    .frame(height: 250)
                                Circle()
                                    .strokeBorder(Color.blue, lineWidth: 1)
                                    .background(Circle()
                                                    .foregroundColor(Color.blue)
                                                    .opacity(0.2))
                                    .frame(width: 220, height: 220, alignment: .center)
                            }
                            HStack{
                                Button(action: {
                                    let coordinate = CLLocationCoordinate2DMake(action.latitude, action.longitude)
                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
                                    mapItem.name = "Action: " + action.name
                                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "car")
                                        Text("Navigate to action using maps")
                                            .font(.body)
                                        Spacer()
                                    }
                                }
                            }
                            Divider()
                        }
                        
                        HStack{
                            Spacer()
                            if(action.id == currentAction){
                                Button(action: {
                                    currentAlert = .leave
                                    showingAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "multiply.circle")
                                        Text("Leave current action")
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
                            }
                            else if(action.is_active){
                                Button(action: {
                                    selectedAction = action
                                    if(currentAction == -1){
                                        currentAlert = .new
                                        showingAlert = true
                                    }
                                    else if(action.id != currentAction){
                                        currentAlert = .change
                                        showingAlert = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle")
                                        Text("Join")
                                            .fontWeight(.semibold)
                                            .font(.body)
                                    }
                                    .padding()
                                    .foregroundColor(.white)
                                    .background(LinearGradient(gradient:Gradient(colors:[Color("JoinButtonDark"), Color("JoinButtonLight")]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(30)
                                    .shadow(radius: 5.0)
                                }
                            }
                            
                            Spacer()
                        }
                        
                    }
                    
                }
                .popup(isPresented: showingPopupActionsDetails, content: {
                    AnimatedImageView()
                })
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.top, -50)
            .padding(.bottom, 50)
        }
        .disabled(showingPopupActionsDetails)
    }
}

struct ActionDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionDetailsView(action: Action.example,
                          showingAlert: .constant(false),
                          currentAlert: .constant(ActiveActionListAlert.new),
                          currentAction: .constant(-1),
                          selectedAction: .constant(Action.example))
    }
}
