//
//  ChatTabView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 04/11/2021.
//

import SwiftUI

struct ChatTabView: View {
    
    @EnvironmentObject var actionListController: ActionListController
    @EnvironmentObject var chatController: ChatController
    
    var body: some View {
        VStack(alignment: .leading) {
            if (actionListController.actionIsSet && chatController.chatAuthorized == .authorized) {
                ChatView().environmentObject(chatController).environmentObject(actionListController)
            } else {
                VStack(alignment: .center) {
                    if #available(iOS 15.0, *) {
                        Text("WelcomeChat").padding(.all, 20).multilineTextAlignment(.center)
                    }
                    else{
                        Text("WelcomeChat-ios14").padding(.all, 20).multilineTextAlignment(.center)
                    }
                    HStack{
                        Text("Stataus: ")
                        Text(chatController.chatAuthorized.description)
                    }.padding(.bottom, 20)
                    if(actionListController.actionIsSet){
                        Button(action: {
                            chatController.loginFromServer(identity: actionListController.GetMyUUID(),
                                                           withSidOrUniqueName: String(actionListController.currentAction),
                                                           completion: chatController.report)
                        }){
                            HStack {
                                Text("Try joining chat room")
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
                        }.disabled(!actionListController.actionIsSet)
                    }
                    else{
                        Text("Join action first.")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
            }
        }
    }
}

