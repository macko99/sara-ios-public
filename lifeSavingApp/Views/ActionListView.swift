//
//  ActionListView.swift
//  lifeSavingApp
//
//  Created by Maciej Kozub on 23/05/2021.
//

import SwiftUI

var showingPopupActionsDetails = false

struct ActionView: View {
    var action: Action
    @Binding var currentAction: Int
    
    //definition of veiw of single entry in list -> one action
    var body: some View {
        VStack(alignment: .leading, content: {
            HStack{
                Text(action.name)
                    .font(.title2)
                    .padding(.top, 1)
                Spacer()
                if (action.id == currentAction){
                    Image(systemName: "checkmark").foregroundColor(.blue)
                    Text("Current").foregroundColor(.blue)
                }
                else if(action.is_active){
                    Text("Active").foregroundColor(.green)
                }
                else {
                    Text("Inactive").foregroundColor(.yellow)
                }
            }
            HStack{
                Text("Starting: \(action.start_time.toDateStringShort)")
                    .font(.caption).italic()
                    .padding(.bottom, 1)
                Spacer()
            }
            Text(action.description)
                .font(.body)
                .padding(.bottom, 5)
                .lineLimit(3)
        })
    }
}

//definition of list view
struct ActionListView: View {
    //injected ActionListController
    @EnvironmentObject var actionListController: ActionListController
    @EnvironmentObject var userLocationController: UserLocationController
    @EnvironmentObject var chatController: ChatController
    
    @State private var showingAlert = false
    @State private var currentAlert = ActiveActionListAlert.change
    @State private var selectedAction = Action.example //MARK: dummy action
    @State private var dummy = false
    @State var showingPopupActionsList = false
    
    var body: some View {
        ZStack{
            VStack{
                HStack{
                    Text("Actions list")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.init(top: 20, leading: 20, bottom: 0, trailing: 20))
                    Spacer()
                    HStack{
                        if(actionListController.loadingStateActions == .loading ||
                           actionListController.loadingStateAreas == .loading ||
                           actionListController.loadingStatePoints == .loading ||
                           actionListController.loadingStateMyAreas == .loading){
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 10.0)
                                .onDisappear(perform: {
                                    showingPopupActionsDetails = false
                                })
                        }
                        else{
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 10.0)
                                .hidden()
                                .onAppear(perform: {
                                    self.showingPopupActionsList = false
                                })
                        }
                        //button for data refreshing
                        Button(action: {
                            showingPopupActionsList = true
                            actionListController.fetchActions()
                            actionListController.fetchAreas()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .padding(.trailing, 10)
                    }
                }.padding(.bottom, -5)
                NavigationView {
                    VStack{
                        //so stupid fix of UI layout using empty list :)
                        List{}.frame(height: 0)
                        //dynamic list of actions, actions from list "actions" in actionListController
                        List{
                            ForEach(actionListController.actions, id: \.self){ item in
                                NavigationLink(destination:
                                                ActionDetailsView(action: item,
                                                                  showingAlert: $showingAlert,
                                                                  currentAlert: $currentAlert,
                                                                  currentAction: $actionListController.currentAction,
                                                                  selectedAction: $selectedAction)){
                                    ActionView(action: item,
                                               currentAction: $actionListController.currentAction)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                    .navigationBarHidden(true)
                }.disabled(showingPopupActionsList)
            }
            .popup(isPresented: showingPopupActionsList, content: {
                AnimatedImageView()
            })
        }
        //definitons of avaialbe alerts
        .alert(isPresented: $showingAlert){
            switch(currentAlert){
            case .change:
                return Alert(title: Text("Are you sure?"),
                             message: Text("If you join this action, you will leave current one. You can participate in one action at the time. Additionally you will start sharing your GPS data."),
                             primaryButton: .default(Text("OK")){
                    showingPopupActionsDetails = true
                    actionListController.joinAction(action: selectedAction.id)
                    actionListController.setCurrentAction(actionId: selectedAction.id)
                    actionListController.setActionIsSet(isSet: true)
                    userLocationController.isActive = true
                    actionListController.getMyAreas()
                    actionListController.fetchAreas()
                    actionListController.fetchUsers()
                    chatController.loginFromServer(identity: actionListController.GetMyUUID(),
                                                   withSidOrUniqueName: String(selectedAction.id),
                                                   completion: chatController.report)
                }, secondaryButton: .default(Text("Cancel")){})
            case .leave:
                return Alert(title: Text("Are you sure?"),
                             message: Text("If you leave action its data saved in device memory will be removed. If you do not have Internet connection at the moment it coud be not possible to regain access to those data untill returning online. Do you still want to leave?"),
                             primaryButton: .default(Text("Yes")){
                    actionListController.leaveAction()
                    actionListController.setCurrentAction(actionId: -1)
                    actionListController.setActionIsSet(isSet: false)
                    userLocationController.isActive = false;
                    chatController.shutdown()
                }, secondaryButton: .default(Text("Cancel")){})
            case .new:
                return Alert(title: Text("Are you sure?"),
                             message: Text("If you join this action you will start sharing your GPS data."),
                             primaryButton: .default(Text("OK")){
                    showingPopupActionsDetails = true
                    actionListController.joinAction(action: selectedAction.id)
                    actionListController.setCurrentAction(actionId: selectedAction.id)
                    actionListController.setActionIsSet(isSet: true)
                    userLocationController.isActive = true;
                    actionListController.getMyAreas()
                    actionListController.fetchAreas()
                    actionListController.fetchUsers()
                    chatController.loginFromServer(identity: actionListController.GetMyUUID(),
                                                   withSidOrUniqueName: String(selectedAction.id),
                                                   completion: chatController.report)
                }, secondaryButton: .default(Text("Cancel")){})
            }
        }
        .onChange(of: userLocationController.isActive) { value in
            if (value) {
                userLocationController.resumeLocationService()
            }
            else {
                userLocationController.killLocationService()
            }
        }
    }
}


struct ActionListView_Previews: PreviewProvider {
    static var previews: some View {
        ActionListView().environmentObject(ActionListController.example)
    }
}
