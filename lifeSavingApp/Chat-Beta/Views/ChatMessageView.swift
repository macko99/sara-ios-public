//
//  ChatMessageView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 04/11/2021.
//

import SwiftUI

struct ChatMessageView: View {
    @State var message: String
    @State var sender: String?
    var alignment: HorizontalAlignment
    @State var avatarColor: Color
    @State var messageBackgroundColor: Color
    @State var time: Date
    
    @State var showingDate = false
    
    var body: some View {
        VStack(alignment: self.alignment) {
            VStack(spacing: 5){
                if((sender) != nil && !sender!.isEmpty){
                    HStack {
                        if alignment == .trailing {
                            Spacer()
                        }
                        Text(sender!.uppercased())
                            .foregroundColor(avatarColor)
                            .font(.footnote)
                        if alignment == .leading {
                            Spacer()
                        }
                    }
                }
                HStack {
                    if alignment == .trailing || alignment == .center {
                        Spacer().frame(maxWidth: UIScreen.screenWidth*0.05)
                        Spacer()
                    }
                    VStack{
                        if(self.showingDate){
                            HStack{
                                Text(Int(time.timeIntervalSince1970).toDateStringShort).font(.caption2)
                            }
                        }
                        VStack(alignment: .leading) {
                            VStack{
                                Text(message).font(.body)
                            }
                            .padding(.all, 10)
                            .background(messageBackgroundColor)
                            .cornerRadius(20)
                        }.foregroundColor((sender != nil && !sender!.isEmpty) ? Color("Text") : .white)
                            .onTapGesture {
                                self.showingDate.toggle()
                            }
                    }
                    
                    if alignment == .leading || alignment == .center {
                        Spacer().frame(maxWidth: UIScreen.screenWidth*0.05)
                        Spacer()
                    }
                }
            }
        }.padding([.leading, .trailing], 20)
    }
}

struct ChatMessageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            if #available(iOS 15, *) {
                ChatMessageView(message: "Hello",
                                alignment: .trailing, avatarColor: .blue, messageBackgroundColor: .blue, time: Date.now)
                ChatMessageView(message: "Hello",
                                alignment: .trailing, avatarColor: .blue, messageBackgroundColor: .blue, time: Date.now)
                ChatMessageView(message: "Hello",
                                alignment: .trailing, avatarColor: .blue, messageBackgroundColor: .blue, time: Date.now)
                ChatMessageView(message: "Hello", sender: "OK",
                                alignment: .leading, avatarColor: .blue, messageBackgroundColor: .gray.opacity(0.5), time: Date.now)
                ChatMessageView(message: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. ", sender: "OK",
                                alignment: .leading, avatarColor: .blue, messageBackgroundColor: .gray.opacity(0.5), time: Date.now)
                ChatMessageView(message: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. ", sender: "OK",
                                alignment: .leading, avatarColor: .blue, messageBackgroundColor: .gray.opacity(0.5), time: Date.now)
                ChatMessageView(message: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.",
                                alignment: .trailing, avatarColor: .blue, messageBackgroundColor: .blue, time: Date.now)
                ChatMessageView(message: "Hello", sender: "OK",
                                alignment: .leading, avatarColor: .blue, messageBackgroundColor: .gray.opacity(0.5), time: Date.now)
                ChatMessageView(message: "Hello",
                                alignment: .trailing, avatarColor: .blue, messageBackgroundColor: .blue, time: Date.now)
            } else {
                // Fallback on earlier versions
            }
            
        }
    }
}
