//
//  BlankStateView.swift
//  The AI
//
//  Created by 梓墨 on 2026/6/14.
//

import SwiftUI

struct BlankStateView: View {
    
    var userVM = UserViewModel()
    
    var body: some View {
        ZStack{
            VStack{
                Spacer()
                Text("Welcome Back!\(String(describing: userVM.username))")
                    .font(.largeTitle)
                Spacer()
            }
        }
    }
}

#Preview {
    BlankStateView()
}
