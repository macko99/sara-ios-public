//
//  LoginView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 02/05/2021.
//

// 

import SwiftUI

var showingPopupLogin = false

struct LoginView: View {
    //login controller injected from main class
    @EnvironmentObject var loginController: LoginController
    
    //variables used for holding user provided information
    @State private var ip = ""
    @State private var username = ""
    @State private var password = ""
    @State private var port = ""
    @State private var useSSL: Bool = true
    //variable using enum - which alrt is currently showing
    @State private var activeAlert: ActiveLoginAlert = .ip
    @State private var usingCode = false
    @State private var showingLoginFailureAlert = false
    @State private var isIpOk = false
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    //default hosting location
    private var defaultAddress = "sara-server.herokuapp.com"
    private var defaultPort = "80"
    
    var body: some View {
        VStack() {
            Spacer()
            HStack{
                Spacer()
                Image("WelcomeImage")
                    .resizable()
                    .frame(width: UIScreen.screenHeight*0.2,
                           height: UIScreen.screenHeight*0.2)
                    .shadow(radius: 10.0, x: 20, y: 10)
                //when user is automatically log out - the proper alrt is attached here
                    .alert(isPresented: $loginController.autoLogout) {
                        Alert(title: Text("Session expired!"),
                              message: Text("You have been logout. Should it be a bug, please contact administration."),
                              dismissButton: .default(Text("OK")))
                    }
                Spacer()
            }
            Spacer()
            Text("Log In to your account")
                .font(.headline)
                .foregroundColor(Color.white)
                .padding(.top, 30)
                .padding(.bottom, 10)
                .shadow(radius: 10.0, x: 20, y: 10)
            
            VStack(alignment: .center, spacing: 15) {
                HStack{
                    Image(systemName: "globe")
                        .foregroundColor(.black)
                    ZStack(alignment: .leading) {
                        if ip.isEmpty { Text(defaultAddress).foregroundColor(.gray) }
                        TextField("", text: $ip)
                    }.foregroundColor(.black)
                }
                .frame(maxWidth: 400)
                .padding()
                .background(Color("TextBox"))
                .cornerRadius(20.0)
                .shadow(radius: 10.0, x: 20, y: 10)
                
                HStack{
                    Image(systemName: useSSL ? "checkmark.square.fill" : "square")
                        .foregroundColor(useSSL ? Color(UIColor.systemGreen) : Color.secondary)
                        .onTapGesture {
                            self.useSSL.toggle()
                        }
                    Text("Use SSL")
                        .font(.headline)
                        .foregroundColor(Color.white)
                    Spacer()
                    HStack{
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if port.isEmpty { Text("Port: 80").foregroundColor(.gray) }
                            TextField("", text: $port)
                                .keyboardType(.numberPad)
                        }.frame(width: 80).foregroundColor(.black)
                    }
                    .padding()
                    .background(Color("TextBox"))
                    .cornerRadius(20.0)
                    .shadow(radius: 5.0, x: 10, y: 5)
                }.frame(maxWidth: 400)
                
                //if user wants to login using login and password
                if (!usingCode){
                    
                    HStack{
                        Image(systemName: "person")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if username.isEmpty { Text("Username").foregroundColor(.gray) }
                            TextField("", text: $username)
                                .autocapitalization(.none)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(Color("TextBox"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    
                    HStack{
                        Image(systemName: "lock")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if password.isEmpty { Text("Pasword").foregroundColor(.gray) }
                            SecureField("", text: $password)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(Color("TextBox"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                    
                }
                //logim via unique one time code
                else{
                    
                    HStack{
                        Image(systemName: "lock.shield")
                            .foregroundColor(.black)
                        ZStack(alignment: .leading) {
                            if password.isEmpty { Text("Code").foregroundColor(.gray) }
                            TextField("", text: $password)
                        }.foregroundColor(.black)
                    }
                    .frame(maxWidth: 400)
                    .padding()
                    .background(Color("TextBox"))
                    .cornerRadius(20.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                }
                
            }.padding([.leading, .trailing], 30)
            
            //login button
            Button(action: {
                showingPopupLogin = true
                if ip.isEmpty{ ip = defaultAddress }
                if port.isEmpty{ port = defaultPort }
                self.isIpOk = loginController.validateIpAddress(ipToValidate: ip, portToValidate: port)
                if(isIpOk){
                    loginController.setIpAddress(newIP: ip, newPort: port, newScheme: useSSL)
                }
                
                //we first check if provided url or ip address is correct then we set it in login controller to be used later to login
                DispatchQueue.global(qos: .userInitiated).async {
                    if(isIpOk){
                        if(!loginController.login(username: username, password: password, usingCode: usingCode)){
                            DispatchQueue.main.async {
                                activeAlert = .cred
                                showingLoginFailureAlert = true
                            }
                        }
                        DispatchQueue.main.async {
                            showingPopupLogin = false
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            showingPopupLogin = false
                            activeAlert = .ip
                            showingLoginFailureAlert = true
                        }
                    }
                }
            }) {
                Text("Log In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.green)
                    .cornerRadius(15.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
                //definitions for two possible alert
                    .alert(isPresented: $showingLoginFailureAlert) {
                        switch activeAlert {
                        case .cred:
                            return Alert(title: Text("Login failed!"),
                                         message: Text("Please check entered credentials."),
                                         dismissButton: .default(Text("Got it!")))
                        case .ip:
                            return Alert(title: Text("Server address validation failed!"),
                                         message: Text("Please check entered addres/ip address or port number and try again."),
                                         dismissButton: .default(Text("Got it!")))
                        }
                    }
            }.padding(.top, 40)
            
            Spacer()
            HStack(spacing: 0) {
                if (!usingCode) { Text("Got one time passcode? ")
                        .foregroundColor(.black)
                }
                else { Text("Back to username and pasword? ")
                        .foregroundColor(.black)
                }
                Button(action: {
                    usingCode.toggle()
                    self.password = ""
                }) {
                    Text("Click Here")
                        .foregroundColor(.black)
                        .bold()
                }
            }
        }
        .popup(isPresented: showingPopupLogin, content: {
            AnimatedImageView()
        })
        //nice gradient backgroud :)
        .background(
            LinearGradient(gradient: Gradient(colors: [.purple, .blue]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView().environmentObject(LoginController.example)
        
    }
}
