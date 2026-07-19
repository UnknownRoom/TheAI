//
//  ListView.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import SwiftUI
import Combine

struct ListView: View {
    
    @ObservedObject var viewModel = ChatViewModel()
    
    var body: some View {
        ScrollViewReader{ proxy in
            ScrollView(.vertical){
                LazyVStack(spacing: 12){
                    if let currentSession = viewModel.currentSession{
                        ForEach(currentSession.messages) { message in
                            MessageCell(message: message).id(message.id)
                        }
                        
                    }else{
                        
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .onChange(of: viewModel.messages.count){ _ , _ in
                if let last = viewModel.messages.last{
                    withAnimation{
                        proxy.scrollTo(last.id,anchor: .bottom)
                        
                    }
                }
            }
        }
    }
}
