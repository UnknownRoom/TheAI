//
//  The_AIApp.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/7.
//

import SwiftUI

@main
struct The_AIApp: App {
    
    @StateObject var userVM = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userVM)
        }
    }
}
