//
//  HomeView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 29/04/2021.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var actionListController: ActionListController
    @EnvironmentObject var userLocationController: UserLocationController
    
    @State private var debugTxt = ""
    @State private var rotation = 0.0
    @State private var scale = 120.0
    
    @State private var showingDebugButtons = false
    @State private var showingAlert = false
    
//    @Binding var experimentalF: Bool
    
    var body: some View {
        VStack{
            Spacer().frame(height: 1)
            ScrollView{
                VStack {
                    HStack{
                        Text("Welcome")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
                        Spacer()
                    }
//                    .onTapGesture(count: 5) {
//                        showingDebugButtons.toggle()
//                    }
                    Spacer().frame(height: 20)
                    
//                    //MARK: debug part, needs to be removed before realse
//                    if(showingDebugButtons && experimentalF){
//                        HStack{
//                            VStack{
//                                Text("DEBUG TOOLS").foregroundColor(.red).fontWeight(.bold)
//                                Text("use **ONLY IF** you know how 😇").foregroundColor(.red)
//                                HStack{
//                                    Button(action: {
//                                        let tmp = actionListController.actionDataController.getAllActions()
//                                        self.debugTxt = "actions count: \(tmp.count)"
//                                    }) {
//                                        Text("action cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        var tmp = [StoredArea]()
//                                        do{
//                                            tmp = try actionListController.actionDataController.getAllAreas()
//                                        }
//                                        catch{}
//                                        self.debugTxt = "areas count: \(tmp.count)"
//                                    }) {
//                                        Text("area cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        var tmp = [StoredCoordinate]()
//                                        do{
//                                            tmp = try actionListController.actionDataController.getAllCoordinates()
//                                        }
//                                        catch{}
//                                        self.debugTxt = "coordinates count: \(tmp.count)"
//                                    }) {
//                                        Text("coord cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        let tmp = actionListController.actionDataController.getAllPoints()
//                                        self.debugTxt = "points count: \(tmp.count)"
//                                    }) {
//                                        Text("point cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                }.padding(.bottom, 5)
//                                HStack{
//                                    Button(action: {
//                                        let tmp = actionListController.usersController.userDataController.getAllUsers()
//                                        self.debugTxt = "users count: \(tmp.count)"
//                                    }) {
//                                        Text("user cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        var tmp = [StoredPath]()
//                                        do{
//                                            tmp = try userLocationController.locationDataController.getUserPath()
//                                        }
//                                        catch{}
//                                        self.debugTxt = "path count: \(tmp.count)"
//                                    }) {
//                                        Text("path cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        actionListController.actionDataController.deleteAllActions()
//                                        actionListController.actionDataController.deleteAllPoints()
//                                        self.debugTxt = "deleted actions + points"
//                                    }) {
//                                        Text("CL A+P")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.black))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        actionListController.usersController.userDataController.deleteAllUsers()
//                                        self.debugTxt = "users removed"
//                                    }) {
//                                        Text("CL U")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.black))
//                                            .cornerRadius(20)
//                                    }
//                                }
//                                HStack{
//                                    Button(action: {
//                                        do{
//                                            let tmp: [StoredLocation] = try userLocationController.locationDataController.getAll()
//                                            self.debugTxt = "cached locations count: \(tmp.count)"
//                                        } catch{}
//                                    }) {
//                                        Text("location cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        let tmp = actionListController.cachePointDataController.getAllPoints()
//                                        self.debugTxt = "cached points count: \(tmp.count)"
//                                    }) {
//                                        Text("cache cn")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.red))
//                                            .cornerRadius(20)
//                                    }
//                                    Button(action: {
//                                        userLocationController.locationDataController.deleteAll()
//                                        actionListController.cachePointDataController.deleteAllPoints()
//                                        self.debugTxt = "removed cached loc + points"
//                                    }) {
//                                        Text("CL L+C")
//                                            .padding()
//                                            .font(.system(size: 10))
//                                            .foregroundColor(.white)
//                                            .background(Color(.black))
//                                            .cornerRadius(20)
//                                    }
//                                }
//                                .padding(.bottom, 5)
//
//                                HStack{
//                                    Text("result... \(debugTxt)")
//                                        .foregroundColor(.red)
//                                    Spacer()
//                                }
//                            }.padding()
//                                .border(.red, width: 5)
//                                .background(Color(.white))
//                        }.padding([.leading, .trailing], 10)
//                    }
//                    else{
//                        HStack{}
//                    }
                    
                    Group{
                        Image("HomeImage")
                            .resizable()
                            .frame(width: CGFloat(scale), height: CGFloat(scale))
                            .rotationEffect(.degrees(rotation))
                            .onTapGesture {
                                self.rotation = (self.rotation + 90).truncatingRemainder(dividingBy: 360)
                            }
                            .onAppear(){
                                let randomInt = Int.random(in: 1..<4)
                                self.rotation = (self.rotation + Double(randomInt)*90).truncatingRemainder(dividingBy: 360)
                            }
                    }
                    
                    HStack{
                        VStack(alignment: .leading, spacing: 20) {
                            if #available(iOS 15.0, *) {
                                Group{
                                    Text("WelcomeMessage")
                                    Text("ModuleOverView")
                                    Text("Quick guide:").bold()
                                }
                                Text("ProfileOverView")
                                Text("ActionsOverView")
                                Text("DataOverView")
                                Text("MapOverView")
                                Text("DataOverViewDetails")
                                Text("PushOverView")
                                Text("OtherOverView")
                                Text("WelcomeChatMainTab")
                            }
                            else{
                                Group{
                                    Text("WelcomeMessage-ios14")
                                    Text("ModuleOverView-ios14")
                                    Text("Quick guide:").bold()
                                }
                                Text("ProfileOverView-ios14")
                                Text("ActionsOverView-ios14")
                                Text("DataOverView-ios14")
                                Text("MapOverView-ios14")
                                Text("DataOverViewDetails-ios14")
                                Text("PushOverView-ios14")
                                Text("OtherOverView-ios14")
                                Text("WelcomeChatMainTab-ios14")
                            }
                        }
                    }.padding()
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding([.top, .bottom], 20)
                    
//                    Spacer()
//                    Text(UIApplication.versionBuild())
//                        .font(.system(size: 8.0))
//                        .onTapGesture(count: 5) {
//                            showingDebugButtons.toggle()
//                        }
                    Spacer()
                        .frame(height: 20)
                }.onAppear(){
                    if(!userLocationController.checkLocationService()){
                        showingAlert = true
                    }
                }.alert(isPresented: $showingAlert){
                    if #available(iOS 15.0, *) {
                        return Alert(title: Text("Location is needed"),
                                     message: Text("AllowAlwaysLocation"),
                                     primaryButton: .default(Text("Go to Settigns")){ openSettings() },
                                     secondaryButton: .default(Text("Dismiss")){showingAlert = false})
                    }
                    else{
                        return Alert(title: Text("Location is needed"),
                                     message: Text("AllowAlwaysLocation-ios14"),
                                     primaryButton: .default(Text("Go to Settigns")){ openSettings() },
                                     secondaryButton: .default(Text("Dismiss")){showingAlert = false})
                    }
                }
            }
        }
    }
    
    func openSettings() {
        if let url = URL(string:UIApplication.openSettingsURLString){
            
            if UIApplication.shared.canOpenURL(url){
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView(/*showingChatBeta: .constant(true)*/)
                .preferredColorScheme(.light)
                .environmentObject(ActionListController.example)
                .environmentObject(UserLocationController.example)
        }
    }
}
