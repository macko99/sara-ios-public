//
//  This is main class which acts as a 'router' - it navigates user between UI for authenticated users and login UI.
//
//  lifeSavingAppApp.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 08/03/2021.
//

import SwiftUI
import CoreLocation


@main
struct lifeSavingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    //     declaration of login controller - provides information whether user is authenticated used to provide corrent UI to user. Is also injected into next views as environment object.
    @StateObject var loginController = LoginController()
    
    var body: some Scene {
        WindowGroup {
            if !loginController.isLoggedin {
                LoginView()
                    .environmentObject(loginController)
                    .transition(AnyTransition.move(edge: .leading)
                                    .combined(with: .opacity)
                                    .animation(.easeInOut(duration: 1)))
            } else {
                MainTabView()
                    .environmentObject(loginController)
                    .transition(AnyTransition.move(edge: .leading)
                                    .combined(with: .opacity)
                                    .animation(.easeInOut(duration: 1)))
            }
        }
    }
}
