//
//  ChnagePasswordView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 13/06/2021.
//

import SwiftUI

struct ChnagePasswordView: View {
    
    @EnvironmentObject var userDataPatchController: UserDataPatchController
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var password = TextLimiter(limit: 30)
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveChangeUsernameAlert = .empty
    
    var body: some View {
        NavigationView {
            VStack{
                Text("Chnage your password")
                    .font(.headline)
                    .padding()
                Divider()
                
                VStack() {
                    HStack{
                        Image(systemName: "lock")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if password.value.isEmpty { Text("New password").foregroundColor(.gray) }
                            SecureField("", text: $password.value)
                                .autocapitalization(.none)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(!password.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    if(password.hasReachedLimit){
                        Text("Exceeded character limit.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding([.top, .bottom], -5)
                            .padding([.trailing, .leading], 20)
                    }
                    
                    Button(action: {
                        if !password.value.isEmpty {
                            let result = userDataPatchController.updatePassword(newPasswd: password.value)
                            switch result {
                            case .success:
                                activeAlert = .success
                                showingAlert = true
                                self.password.value = ""
                            default:
                                activeAlert = .faild
                                showingAlert = true
                                self.password.value = ""
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
                            .background(password.hasReachedLimit ? Color.gray : Color.green)
                            .cornerRadius(15.0)
                            .shadow(radius: 10.0, x: 20, y: 10)
                            .alert(isPresented: $showingAlert) {
                                switch activeAlert {
                                case .empty:
                                    return Alert(title: Text("Passwod field empty!"),
                                                 message: Text("Please enter new password if you want to change current one."),
                                                 dismissButton: .default(Text("Got it!")))
                                case .success:
                                    return Alert(title: Text("Password updated!"),
                                                 message: Text("You can go back to using the app."),
                                                 dismissButton: .default(Text("Got it!")){
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                default:
                                    return Alert(title: Text("Something went wrong!"),
                                                 message: Text("Please try again later."),
                                                 dismissButton: .default(Text("Got it!")){
                                        self.presentationMode.wrappedValue.dismiss()
                                    })
                                }
                            }
                    }.padding(.top, 30)
                        .disabled(password.hasReachedLimit)
                }.padding(.top, 30)
            }.padding()
                .navigationBarItems(trailing: Button("Cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                })
        }
    }
}

struct ChnagePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ChnagePasswordView().environmentObject(UserDataPatchController.example)
    }
}
