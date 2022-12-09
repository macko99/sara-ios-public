//
//  ChatController.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 04/11/2021.
//

import UIKit
import TwilioConversationsClient


class ChatController: NSObject, TwilioConversationsClientDelegate, ObservableObject {
    
    weak var delegate: QuickstartConversationsManagerDelegate?
    private var client: TwilioConversationsClient?
    private var conversation: TCHConversation?
    
    @Published var messages: [TCHMessage] = []
    @Published var chatAuthorized = ChatAuthorizedStatus.notActive
    
    var identity: String?
    var uniqueConversationName: String?
    
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardIsShown: Bool = false

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keybordDidShow),
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil
                )
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(keyboardDidHide),
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil
                )
    }

    @objc func keybordDidShow(_ notification: Notification) {
        keyboardIsShown = true
        }
    @objc func keyboardDidHide(_ notification: Notification) {
        keyboardIsShown = false
        }
    
    func conversationsClient(_ client: TwilioConversationsClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        guard status == .completed else {
            return
        }
        
        checkConversationCreation { (_, conversation) in
            if let conversation = conversation {
                self.joinConversation(conversation)
            }
            else {
                self.createConversation { (success, conversation) in
                    if success, let conversation = conversation {
                        self.joinConversation(conversation)
                    }
                }
            }
        }
    }
    
    // Called whenever a conversation we've joined receives a new message
    func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation, messageAdded message: TCHMessage) {
        messages.append(message)
        
        DispatchQueue.main.async {
            if let delegate = self.delegate {
                delegate.reloadMessages()
                delegate.receivedNewMessage()
            }
        }
    }
    
    func conversationsClientTokenWillExpire(_ client: TwilioConversationsClient) {
        refreshAccessToken()
    }
    
    func conversationsClientTokenExpired(_ client: TwilioConversationsClient) {
        refreshAccessToken()
    }
    
    private func refreshAccessToken() {
        guard let identity = identity else {
            return
        }
        
        ChatUtils.retrieveToken(id: identity) { (token, _, error) in
            guard let token = token else {
                return
            }
            if token == "service is not active" {
                DispatchQueue.main.async {
                    self.chatAuthorized = .notAvailable
                }
                return
            }
            self.client?.updateToken(token, completion: { (result) in
                if (result.isSuccessful) {
                }
                else {
                }
            })
        }
    }
    
    func sendMessage(_ messageText: String, completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        let messageOptions = TCHMessageOptions().withBody(messageText)
        conversation?.sendMessage(with: messageOptions, completion: {
            (result, message) in completion(result, message)
        })
    }
    
    func loginFromServer(identity: String, withSidOrUniqueName: String, completion: @escaping (Bool) -> Void) {
        if(identity.isEmpty || withSidOrUniqueName.isEmpty){
            completion(false)
            return
        }
        self.identity = identity
        self.uniqueConversationName = withSidOrUniqueName
        
        ChatUtils.retrieveToken(id: identity) { (token, _, error) in
            guard let token = token else {
                completion(false)
                return
            }
            
            if token == "service is not active" {
                DispatchQueue.main.async {
                    self.chatAuthorized = .notAvailable
                }
                completion(false)
                return
            }
            
            TwilioConversationsClient.conversationsClient(withToken: token,
                                                          properties: nil,
                                                          delegate: self) { (result, client) in
                self.client = client
                completion(result.isSuccessful)
            }
        }
    }
    
    func report(res: Bool){
        if (res){
            DispatchQueue.main.async {
                self.chatAuthorized = .loading
            }
        }
        else{
            DispatchQueue.main.async {
                if self.chatAuthorized != .notAvailable {
                    self.chatAuthorized = .failed
                }
            }
        }
    }
    
    func loginWithAccessToken(_ token: String) {
        TwilioConversationsClient.conversationsClient(withToken: token,
                                                      properties: nil,
                                                      delegate: self) { (result, client) in
            self.client = client
        }
    }
    
    func shutdown() {
        if let client = client {
            client.delegate = nil
            client.shutdown()
            self.client = nil
            DispatchQueue.main.async {
                self.chatAuthorized = .notActive
                self.delegate?.displayStatusMessage("shutdown")
            }
        }
    }
    
    private func createConversation(_ completion: @escaping (Bool, TCHConversation?) -> Void) {
        guard let client = client else {
            return
        }
        if (uniqueConversationName == nil){
            return
        }
        // Create the conversation if it hasn't been created yet
        let options: [String: Any] = [TCHConversationOptionUniqueName: uniqueConversationName!]
        client.createConversation(options: options) { (result, conversation) in
            if result.isSuccessful {
            }
            else {
            }
            completion(result.isSuccessful, conversation)
        }
    }
    
    private func checkConversationCreation(_ completion: @escaping(TCHResult?, TCHConversation?) -> Void) {
        guard let client = client else {
            DispatchQueue.main.async {
                self.chatAuthorized = .failed
            }
            return
        }
        if (uniqueConversationName == nil){
            DispatchQueue.main.async {
                self.chatAuthorized = .failed
            }
            return
        }
        client.conversation(withSidOrUniqueName: uniqueConversationName!) { (result, conversation) in
            completion(result, conversation)
        }
    }
    
    private func joinConversation(_ conversation: TCHConversation) {
        self.conversation = conversation
        if conversation.status == .joined {
            self.loadPreviousMessages(conversation)
            DispatchQueue.main.async {
                self.chatAuthorized = .authorized
            }
            return
        }
        else {
            conversation.join(completion: { result in
                if result.isSuccessful {
                    self.loadPreviousMessages(conversation)
                    DispatchQueue.main.async {
                        self.chatAuthorized = .authorized
                    }
                    return
                }
            })
        }
        DispatchQueue.main.async {
            self.chatAuthorized = .failed
        }
    }
    
    private func loadPreviousMessages(_ conversation: TCHConversation) {
        conversation.getLastMessages(withCount: 100) { (result, messages) in
            if let messages = messages {
                self.messages = messages
                
                DispatchQueue.main.async {
                    self.delegate?.reloadMessages()
                }
            }
        }
    }
}
