//
//  UserInfoView.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/27.
//

import SwiftUI

struct UserInfoView: View {
    
    @ObservedObject var userVM: UserViewModel
    
    
    var body: some View {
        HStack{
            ZStack{
                Circle()
                    .fill(Color.gray.opacity(0.2)) // 给圆圈加个底色
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
            }
            
            Button{
                userVM.isShowingLoginView = true
            }label: {
                Text(userVM.displayName)
                    .foregroundColor(.blue)
                    .underline()
            }
            .buttonStyle(.plain)
            .sheet(isPresented:$userVM.isShowingLoginView){
                LoginView()
                    .padding(6)
                    .frame(width: 450,height: 550)
                
            }
        }
    }
        
}


