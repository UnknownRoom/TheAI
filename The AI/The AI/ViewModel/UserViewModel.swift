//
//  UserViewModel.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/28.
//

import SwiftUI
import Combine          //you need this import to use the ObservableObject

final class UserViewModel: ObservableObject{
    
    @AppStorage("username") var username: String?
    @Published var user = User()
    @Published var isShowingLoginView = false
    @Published var isLoggedIn = false

    func saveUserInfo(){
        if !user.username.isEmpty{
            isLoggedIn = true
        }
        UserDefaults.standard.set(user.username, forKey: "username")
    }
    var displayName: String{
        if let name = username{
            print(name)
            return name
        }else{
            return "请登录"
        }
        
        
    }
}
