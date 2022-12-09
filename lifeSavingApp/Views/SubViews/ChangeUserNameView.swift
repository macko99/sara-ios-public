//
//  ChangeUserNameView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 13/06/2021.
//

import SwiftUI

struct ChangeUserNameView: View {
    
    @EnvironmentObject var userDataPatchController: UserDataPatchController
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var username = TextLimiter(limit: 30)
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveChangeUsernameAlert = .empty
    
    var body: some View {
        NavigationView {
            VStack{
                
                Text("Chnage your username")
                    .font(.headline)
                    .padding()
                
                Divider()
                
                VStack() {
                    HStack{
                        Image(systemName: "person")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if username.value.isEmpty { Text("New username").foregroundColor(.gray) }
                            TextField("", text: $username.value)
                                .autocapitalization(.none)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(!username.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    if(username.hasReachedLimit){
                        Text("Exceeded character limit.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding([.top, .bottom], -5)
                            .padding([.trailing, .leading], 20)
                    }
                    
                    
                    Button(action: {
                        if !username.value.isEmpty {
                            let result = userDataPatchController.updateUserName(newUsername: username.value)
                            switch result {
                            case .usernameTaken:
                                activeAlert = .taken
                                showingAlert = true
                                self.username.value = ""
                            case .success:
                                activeAlert = .success
                                showingAlert = true
                                self.username.value = ""
                            default:
                                activeAlert = .faild
                                showingAlert = true
                                self.username.value = ""
                            }
                        }
                        else{
                            activeAlert = .empty
                            showingAlert = true
                        }
                    }) {
                        Text("Change!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 50)
                            .background(username.hasReachedLimit ? Color.gray : Color.green)
                            .cornerRadius(15.0)
                            .shadow(radius: 10.0, x: 20, y: 10)
                            .alert(isPresented: $showingAlert) {
                                switch activeAlert {
                                case .taken:
                                    return Alert(title: Text("Request failed!"),
                                                 message: Text("Username is already taken!"),
                                                 dismissButton: .default(Text("Got it!")))
                                case .empty:
                                    return Alert(title: Text("Username field empty!"),
                                                 message: Text("Please enter new username if you want to change current one."),
                                                 dismissButton: .default(Text("Got it!")))
                                case .faild:
                                    return Alert(title: Text("Something went wrong!"),
                                                 message: Text("Please try again later."),
                                                 dismissButton: .default(Text("Got it!")){
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                case .success:
                                    return Alert(title: Text("Username updated!"),
                                                 message: Text("You can go back to using the app."),
                                                 dismissButton: .default(Text("Got it!")){
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                }
                            }
                    }.padding(.top, 30)
                        .disabled(username.hasReachedLimit)
                }.padding(.top, 30)
            }.padding()
                .navigationBarItems(trailing: Button("Cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

struct ChangeUserNameView_Preview: PreviewProvider {
    static var previews: some View {
        ChangeUserNameView().environmentObject(UserDataPatchController.example)
    }
}
