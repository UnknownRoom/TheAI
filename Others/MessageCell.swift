//
//  MessageCell.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import SwiftUI

struct MessageCell: View {
    
    let message: Message
    var chatvm = ChatViewModel()
    
    var body: some View {
        HStack(alignment: .top,spacing: 12){
            
            if message.role != .assistant{
                Spacer(minLength: 60)
            }
            
            contentBody
                .textSelection(.enabled)
            
            if message.role != .user{
                Spacer(minLength: 60)
            }
        }
        .padding(.vertical,12)
        .padding(.horizontal,24)
        
    }
    @ViewBuilder
    private var contentBody: some View{
        if message.role == .user{
            Text(message.content)
                .font(.system(.body,design: .rounded))
                .fontWeight(.medium)
                .padding(.horizontal,14)
                .padding(.vertical,10)
                .background(RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlAccentColor))
                )
                .foregroundStyle(.white)
        }else{
            VStack(alignment: .leading, spacing: 8){
                if message.content.isEmpty && chatvm.loadingState == .loading{
                    loadingIndicator
                }else{
                    Group{
                        if chatvm.loadingState == .loading{
                            Text(" ▍ \(message.content)") 
                                .foregroundColor(.accentColor)
                        }else{
                            Text(message.content)
                        }
                    }
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundStyle(.primary)
                }
            }
            .frame(maxWidth: 700, alignment: .leading)
        }
    }
    private var loadingIndicator: some View{
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .offset(y: animateDots ? -4 : 0)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                        value: animateDots
                    )
            }
        }
        .padding(.vertical, 8)
        .onAppear { animateDots = true }
    }
    
    @State private var animateDots = false
}


