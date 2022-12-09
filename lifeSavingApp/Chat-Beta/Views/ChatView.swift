//
//  ChatView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 04/11/2021.
//

import SwiftUI
import TwilioConversationsClient

struct ChatView: View {
    @State private var writing: Bool = false
    @State private var inputText: String = ""
    
    @EnvironmentObject private var chatController: ChatController
    @EnvironmentObject var actionListController: ActionListController
    
    var body: some View {
        VStack{
            HStack{
                HStack{
                    Text("Chat")
                        .font(.largeTitle).fontWeight(.bold)
                    Text("beta").font(.caption).italic().baselineOffset(15).foregroundColor(.orange)
                }.padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
                Spacer()
                Button(action: chatController.shutdown) {
                    Text("Quit")
                }.padding(.trailing, 10.0)
            }
            Divider().padding([.bottom, .top], -10)
            ScrollViewReader { value in
                ScrollView {
                    ForEach (chatController.messages, id: \.id) { msg in
                        let isMine =  msg.author == chatController.identity ? true : false
                        let avatar = actionListController.getAvatar(isMine: isMine, uuid: msg.author!)
                        let index = chatController.messages.firstIndex(of: msg)
                        
                        if(chatController.messages.first == msg){
                            HStack{
                                Text(Int(msg.dateCreatedAsDate!.timeIntervalSince1970).toDateStringShort)
                                    .font(.caption2).italic()
                            }
                        }
                        else{
                            let previousMsg = chatController.messages[(index!-1)]
                            if (msg.dateCreatedAsDate!.timeIntervalSince1970 - previousMsg.dateCreatedAsDate!.timeIntervalSince1970 > 10800){
                                HStack{
                                    Text(Int(msg.dateCreatedAsDate!.timeIntervalSince1970).toDateStringShort)
                                        .font(.caption2).italic()
                                }
                            }
                        }
                        ChatMessageView(message: msg.body!,
                                        sender: avatar.avatar,
                                        alignment: isMine ? .trailing : .leading,
                                        avatarColor: Color(UIColor(hex: avatar.color)!),
                                        messageBackgroundColor: isMine ? .blue : .gray.opacity(0.5),
                                        time: msg.dateCreatedAsDate!).id(msg.id)
                    }
                }.onAppear {
                    value.scrollTo(chatController.messages.last?.id)
                }.onChange(of: chatController.messages.count) { _ in
                    value.scrollTo(chatController.messages.last?.id)
                }
                .onChange(of: self.writing) { _ in
                    value.scrollTo(chatController.messages.last?.id)}
            }.padding(.top, -10)
            Group{
                HStack {
                    if(chatController.keyboardIsShown){
                        Button(action: endTextEditing){
                            Image(systemName: "menubar.arrow.down.rectangle")
                                .padding(.all, 5)
                        }
                    }
                    TextField(NSLocalizedString("New message", comment: ""), text: $inputText, onEditingChanged: { editing in
                        withAnimation {
                            self.delayScrolling(newValue: editing)
                        }}, onCommit: send)
                        .keyboardType(.default)
                        .padding(.all, 10)
                        .background(Color("ChatBox"))
                        .cornerRadius(20)
                        .foregroundColor(Color("Text"))
                    Button(action: send) {
                        Image(systemName: "paperplane.fill").scaleEffect(1.5)
                            .padding(.all, 5)
                    }.disabled(self.inputText == "")
                }.padding([.leading, .trailing], 10)
                    .padding(.bottom, 10)
            }
        }
    }
    
    private func delayScrolling(newValue: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.writing = newValue
        }
    }
    
    func send() {
        if self.inputText == "" {
            return
        }
        self.chatController.sendMessage(self.inputText, completion: report)
        self.inputText = ""
    }
    
    func report(_input: TCHResult, _input2: TCHMessage?){
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView().environmentObject(ChatController())
    }
}
