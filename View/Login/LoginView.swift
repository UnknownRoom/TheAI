//
//  LoginView.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/26.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var userVM: UserViewModel
    
    var body: some View {
        NavigationView{
            Form{
                Section(header: Text("Personal Info")){
                    TextField("User Name", text:$userVM.user.username)
                    TextField("Email", text:$userVM.user.email)
                        .autocorrectionDisabled(true)
                    Button{
                        userVM.saveUserInfo()
                        userVM.isShowingLoginView = false
                    }label: {
                        Text("Save Changes")
                    }
                }
                
            }
            .frame(width: 400,height: 500)
            .padding(6)
            .navigationTitle("🤓 Account")
        }
    }
}


