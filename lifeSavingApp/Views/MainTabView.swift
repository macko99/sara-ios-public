//
//  this view is just responsible for botton navigation bar, it provides it for every other view and provides also refers to classes defined below
//
//  by default it shows first view - HomeView
//  MainTabView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//

let mapView = MKMapView()

import SwiftUI
import MapKit

struct MainTabView: View {
    //login controller incjected from main class
    @EnvironmentObject var loginController: LoginController
    //definitions of two controllers: action list and user location. Those are next injected to proper views
    @StateObject var actionListController = ActionListController()
    @StateObject var userLocationController = UserLocationController()
    @StateObject var chatController = ChatController()
    
    var body: some View {
        TabView{
            HomeView(/*experimentalF: $loginController.experimentalFeatures*/).environmentObject(actionListController).environmentObject(userLocationController)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            MapView().environmentObject(actionListController).environmentObject(userLocationController)
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
            ActionListView().environmentObject(actionListController).environmentObject(userLocationController).environmentObject(chatController)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Actions")
                }
            ChatTabView().environmentObject(actionListController).environmentObject(chatController)
                .tabItem {
                    Image(systemName: "ellipsis.bubble.fill")
                    Text("Chat (beta)")
                }
            ProfileView()
                .environmentObject(actionListController).environmentObject(userLocationController).environmentObject(loginController)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }.onAppear(){
            //fix ios 15 nav bar! they made it transparent :/ back to old way
            if #available(iOS 15.0, *) {
                let appearance = UITabBarAppearance()
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
            //every time app is opened it fetches actions from server (as it may change often) and fetches users from DB (other users data is used for showing who has added some annotation on map) but first checking if token is still valid
            loginController.isTokenValid()
            
            actionListController.fetchActions()
            actionListController.fetchAreas()
            actionListController.fetchUsers()
            if(actionListController.actionIsSet){
                chatController.loginFromServer(identity: actionListController.GetMyUUID(),
                                               withSidOrUniqueName: String(actionListController.currentAction),
                                               completion: chatController.report)
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            if(UIApplication.shared.applicationIconBadgeNumber != 0){
                actionListController.fetchActions()
                actionListController.fetchAreas()
                actionListController.fetchUsers()
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            loginController.isTokenValid()
        }
        .alert(isPresented: $loginController.showingChangePasswordAlert){
            Alert(title: Text("Set your password!"),
                  message: Text("Please go to Profile tab and set your password by clicking Change password. Otherwise you may be not able to log in again."),
                  dismissButton: .default(Text("OK")))
        }
    }
}
