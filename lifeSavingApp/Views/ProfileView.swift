//
//  ProfileView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//
import SwiftUI

var showingPopupProfile = false

struct ProfileView: View {
    
    //declaation of user patch controller used for updating user data to server
    @StateObject var userDataPatchController = UserDataPatchController()
    @EnvironmentObject var loginController: LoginController
    @EnvironmentObject var userLocationController: UserLocationController
    @EnvironmentObject var actionListController: ActionListController
    
    @State var showChangeUsername = false
    @State var showChangePassword = false
    @State var showChangeWidth = false
    @State var showChangeNames = false
    
    let defaults = UserDefaults.standard
    
    var body: some View {
        VStack{
            HStack{
                Text("Hello")
                    .font(.largeTitle).fontWeight(.bold)
                    .padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
                Spacer()
                HStack{
                    if(loginController.loadingUserData == .loading){
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                            .padding(.trailing, 10.0)
                    }
                    else{
                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                            .padding(.trailing, 10.0)
                            .hidden().onDisappear(perform: {
                                showingPopupProfile = false
                            })
                    }
                    Button(action: {
                        showingPopupProfile = true
                        loginController.getUserData()
                        
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .padding(.trailing, 10.0)
                }
            }
            VStack(alignment: .center, spacing: 5){
                Text(defaults.string(forKey: "firstName") ?? "please refresh")
                    .font(.largeTitle).fontWeight(.medium)
                Text(defaults.string(forKey: "lastName") ?? "please refresh")
                    .font(.title2).fontWeight(.medium)
            }.padding(.top, 1)
            
            HStack{
                VStack(alignment: .leading, spacing: UIScreen.screenHeight > 700 ? 21 : 13){
                    Divider()
                    HStack{
                        Text("Username:").fontWeight(.medium)
                        Spacer()
                        Text(defaults.string(forKey: "username") ?? "please refresh")
                            .font(.body)
                        Button(action: {
                            showChangeUsername = true
                        }) {
                            Image(systemName: "highlighter")
                        }
                        //show change username view in a sheet
                        .sheet(isPresented: $showChangeUsername) {
                            ChangeUserNameView()
                                .environmentObject(userDataPatchController)
                                .onDisappear(perform: {
                                    //refresh user data after closing edit view
                                    loginController.getUserData()
                                })
                        }
                    }
                    HStack{
                        Text("Phone number:").fontWeight(.medium)
                        Spacer()
                        Button(action: {
                            let number = defaults.string(forKey: "phone") ?? "please refresh"
                            let formattedString = "tel://" + number
                            guard let url = URL(string: formattedString) else { return }
                            UIApplication.shared.open(url)
                        }) {
                            HStack{
                                Image(systemName: "phone.fill")
                                Text(defaults.string(forKey: "phone") ?? "please refresh")
                            }
                        }
                    }
                    Divider()
                    VStack{
                        Toggle("Collecting location data", isOn: $userLocationController.isActive)
                            .font(Font.body.weight(.medium))
                            .disabled(!actionListController.actionIsSet)
                        if(!actionListController.actionIsSet){
                            Text("To collect data please join action first.")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                                .padding(-5)
                        }
                    }
                    HStack{
                        Text("GPS data upload interval:").fontWeight(.medium)
                        Spacer()
                        Text(String(loginController.pushInterval) + "s")
                    }
                    HStack{
                        Text("Last successful upload:").fontWeight(.medium)
                        Spacer()
                        Text((userLocationController.connectionSuccessTime ?? "-"))
                    }
                    HStack{
                        Text("Width of observation:").fontWeight(.medium)
                        Spacer()
                        Picker("Width of observation", selection: $loginController.observationWidth) {
                            ForEach(5...50, id: \.self) {
                                Text("\($0)m")
                            }
                        }.pickerStyle(.menu)
                            .onChange(of: loginController.observationWidth) { value in
                                defaults.set(value, forKey: "observationWidth")
                            }
                    }
                    Group{
                        Divider()
                        HStack{
                            Spacer()
                            Button(action: {
                                showChangeNames = true
                            }) {
                                Text("Chnage first or last name")
                                Image(systemName: "highlighter")
                            }
                            //show change names view in a sheet
                            .sheet(isPresented: $showChangeNames) {
                                ChangeNamesView(oldFirstName: defaults.string(forKey: "firstName") ?? "please refresh",
                                                oldLastName: defaults.string(forKey: "lastName") ?? "please refresh")
                                    .environmentObject(userDataPatchController)
                                    .onDisappear(perform: {
                                        //refresh user data after closing edit view
                                        loginController.getUserData()
                                    })
                            }
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            Button(action: {
                                showChangePassword = true
                            }) {
                                HStack{
                                    Text("Chnage password")
                                    Image(systemName: "highlighter")
                                }
                            }
                            Spacer()
                        }
                    }
                    //show change username view in a sheet
                    .sheet(isPresented: $showChangePassword) {
                        ChnagePasswordView()
                            .environmentObject(userDataPatchController)
                    }
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
            Spacer()
            Button(action: {
                userLocationController.killLocationService()
                actionListController.setCurrentAction(actionId: -1)
                actionListController.setActionIsSet(isSet: false)
                loginController.logout()
            }) {
                HStack {
                    Image(systemName: "eject")
                    Text("Log Out")
                        .fontWeight(.light)
                        .font(.body)
                }
                .padding()
                .foregroundColor(.white)
                .background(LinearGradient(gradient: Gradient(colors: [Color("LogOutButtonDark"), Color("LogOutButtonLight")]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(40)
                .shadow(radius: 5.0)
            }
            Spacer()
        }
        .popup(isPresented: showingPopupProfile, content: {
            AnimatedImageView()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    
    static var previews: some View {
        ProfileView().preferredColorScheme(.light)
            .environmentObject(LoginController.example)
            .environmentObject(UserLocationController.example)
            .environmentObject(ActionListController.example)
    }
}
