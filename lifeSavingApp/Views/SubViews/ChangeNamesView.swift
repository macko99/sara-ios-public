//
//  ChnagePasswordView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 13/06/2021.
//

import SwiftUI

struct ChangeNamesView: View {
    
    var oldFirstName: String
    var oldLastName: String
    
    @EnvironmentObject var userDataPatchController: UserDataPatchController
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var firstName = TextLimiter(limit: 30)
    @ObservedObject private var lastName = TextLimiter(limit: 30)
    
    @State private var showingAlert = false
    @State private var activeAlert: ActiveChangeUsernameAlert = .empty
    
    var body: some View {
        NavigationView {
            VStack{
                Text("Chnage your information")
                    .font(.headline)
                    .padding()
                Divider()
                
                VStack() {
                    HStack{
                        Image(systemName: "person")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if firstName.value.isEmpty { Text("First name").foregroundColor(.gray) }
                            TextField("", text: $firstName.value)
                                .autocapitalization(.none)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(!firstName.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    if(firstName.hasReachedLimit){
                        Text("Exceeded character limit.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding([.top, .bottom], -5)
                            .padding([.trailing, .leading], 20)
                    }
                    
                    HStack{
                        Image(systemName: "person")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if lastName.value.isEmpty { Text("Last name").foregroundColor(.gray) }
                            TextField("", text: $lastName.value)
                                .autocapitalization(.none)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(!lastName.hasReachedLimit ? Color("TextBox") : Color("OverLimit"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    .padding(.top, 10)
                    if(lastName.hasReachedLimit){
                        Text("Exceeded character limit.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding([.top, .bottom], -5)
                            .padding([.trailing, .leading], 20)
                    }
                    
                    Button(action: {
                        if didValuesChanged() {
                            let result = userDataPatchController.updateNames(
                                newFirstName: firstName.value, newLastName: lastName.value)
                            switch result {
                            case .success:
                                activeAlert = .success
                                showingAlert = true
                                self.firstName.value = ""
                                self.lastName.value = ""
                            default:
                                activeAlert = .faild
                                showingAlert = true
                                self.firstName.value = ""
                                self.lastName.value = ""
                            }
                        }
                        else{
                            //use empty as indicatior that none changes have been made
                            activeAlert = .empty
                            showingAlert = true
                        }
                    }) {
                        Text("Change!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 300, height: 50)
                            .background((firstName.hasReachedLimit || lastName.hasReachedLimit)
                                        ? Color.gray : Color.green)
                            .cornerRadius(15.0)
                            .shadow(radius: 10.0, x: 20, y: 10)
                            .alert(isPresented: $showingAlert) {
                                switch activeAlert {
                                case .empty:
                                    return Alert(title: Text("No change has been done to current values."),
                                                 message: Text("If you wish please enter new values."),
                                                 dismissButton: .default(Text("Got it!")))
                                case .success:
                                    return Alert(title: Text("Values updated!"),
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
                        .disabled(firstName.hasReachedLimit || lastName.hasReachedLimit)
                }.padding(.top, 30)
            }.padding()
                .navigationBarItems(trailing: Button("Cancel") {
                    self.presentationMode.wrappedValue.dismiss()
                })
        }
    }
    
    func didValuesChanged() -> Bool{
        if (!firstName.value.isEmpty && firstName.value != oldFirstName){
            return true
        }
        if (!lastName.value.isEmpty && lastName.value != oldLastName){
            return true
        }
        return false
    }
}

struct ChangeNamesView_Previews: PreviewProvider {
    static var previews: some View {
        ChangeNamesView(oldFirstName: "maciek", oldLastName: "maciek1"
        ).environmentObject(UserDataPatchController.example)
    }
}
