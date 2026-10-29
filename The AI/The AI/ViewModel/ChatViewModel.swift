//
//  ChatViewModel.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject{
    enum LoadingState:Equatable {
        case idle
        case loading
        case streaming
        case failed(errorMessage: String)
    }
    
    @Published var sessions: [Session] = []
    @Published var currentSessionID: UUID?
    
    @Published var messages: [Message] = []
    @Published var prompt: String = ""
    @Published var searchtext = ""
    @Published var loadingState: LoadingState = .idle
    
    var currentSession: Session? {
           sessions.first { $0.id == currentSessionID }
       }
    func createNewSession() {
        let newSession = Session(id: UUID(), title: "新对话", messages: [])
            sessions.insert(newSession, at: 0)
            currentSessionID = newSession.id
        }
    init() {
            createNewSession()
        }
    func selectSession(_ session: Session){
        currentSessionID = session.id
    }
        
    func sendMessage(_ text:String) async {
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        /*guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else{ return }*/ //old
        guard let index = sessions.firstIndex(where: { $0.id == currentSessionID }) else { return } //new
                
        let userMessage = Message(id: UUID(), role: .user, content: trimmedText)
        sessions[index].messages.append(userMessage)
        
        self.prompt = ""
        loadingState = .loading
        
        let history = sessions[index].messages.map{
            AIManager.ChatRequest.Message(role: $0.role.rawValue, content: $0.content)
        }
        let assistantMessageID = UUID()
        let placeholderAssistantMessage = Message(id: assistantMessageID, role: .assistant, content: "")
                sessions[index].messages.append(placeholderAssistantMessage)

        Task{
            do{
                let stream = try await AIManager.shared.send(history: history)
                loadingState = .streaming
                for try await textChunk in stream {
                    if let sessionIndex = self.sessions.firstIndex(where: { $0.id == self.currentSessionID }),
                       let messageIndex = self.sessions[sessionIndex].messages.firstIndex(where: { $0.id == assistantMessageID }) {
                        
                        // 实时追加文字碎片
                        self.sessions[sessionIndex].messages[messageIndex].content += textChunk
                    }
                }
                if let sessionIndex = self.sessions.firstIndex(where: {$0.id == self.currentSessionID}){
                    if self.sessions[sessionIndex].title == "新对话" || sessions[sessionIndex].title.isEmpty {
                        sessions[sessionIndex].title = String(trimmedText.prefix(10))
                    }
                }
                loadingState = .idle
            }catch{
                loadingState = .failed(errorMessage: error.localizedDescription)
                if let sessionIndex = self.sessions.firstIndex(where: {$0.id == self.currentSessionID}),
                   let messageIndex = self.sessions[sessionIndex].messages.firstIndex(where: {$0.id == assistantMessageID}){
                    self.sessions[sessionIndex].messages[messageIndex].content = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
