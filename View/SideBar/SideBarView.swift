//
//  SidebarView.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/26.
//

import SwiftUI

struct SideBarView: View {
    
    @State var searchtext = ""
    @EnvironmentObject var userVM: UserViewModel
    @ObservedObject var chatVM: ChatViewModel
    
    var body: some View {
        VStack{
            Button{
                chatVM.createNewSession()
            }label: {
                Text("New Chat")
            }.padding()
            
            List(chatVM.sessions){ session in
                Button(action: {
                    chatVM.selectSession(session)
                    }){
                    Text(session.title)
                    .lineLimit(1)
                }
                    
            }
//            .searchable(text: $chatVM.searchtext)
            Spacer()
            UserInfoView(userVM: userVM)
                
                

        }
    }
}


