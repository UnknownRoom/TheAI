//
//  ContentView.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/7.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationSplitView{
            SideBarView(chatVM: viewModel)
        }detail: {
            VStack {
                Spacer()
                if viewModel.messages.isEmpty && viewModel.loadingState == .idle{
                   BlankStateView()
                }else{
                    ListView(viewModel: viewModel)
                }
                
                InputBar(prompt: $viewModel.prompt){
                    Task{
                        await viewModel.sendMessage(viewModel.prompt)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
