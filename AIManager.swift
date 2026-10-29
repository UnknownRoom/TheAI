//
//  AIManager.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import Foundation
import Combine
import AppKit
import SwiftUI

class AIManager: ObservableObject{
    
    static let shared = AIManager()
    private init (){}
    private let bindvm = BindViewModel.shared
   
    struct ChatRequest: Codable{
        let model: String
        let messages: [Message]
        let stream: Bool
        
        struct Message: Codable{
            let role: String
            let content: String
        }
    }
    
    struct ChatStreamResponse: Codable{
        
        let choices: [Choices]
        struct Choices: Codable{
            let delta: Delta
        }
        
        struct Delta: Codable{
            let content: String?
        }
        
    }

    
    
    func send(history: [ChatRequest.Message],model: String? = nil)async throws ->AsyncThrowingStream<String,Error>{
         AsyncThrowingStream{continuation in
            Task{
                do{
                    guard let url = chatCompletionsURL(from: bindvm.BaseURL) else{
                        continuation.finish(throwing: URLError(.badURL))
                        return
                    }
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.addValue("Bearer \(bindvm.APIKey)", forHTTPHeaderField: "Authorization")
                    
                    let requestBody = ChatRequest(
                        model: model ?? bindvm.ModelName,
                        messages: history,
                        stream: true
                    )
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else{
                        continuation.finish(throwing: URLError(.badServerResponse))
                        return
                    }
                    for try await line in bytes.lines {
                        if line.hasPrefix("data: "){
                            let jsonString = line.dropFirst(6).trimmingCharacters(in: .whitespacesAndNewlines)
                            if jsonString == "[DONE]"{
                                break
                            }
                            if let data = jsonString.data(using: .utf8),let chunk = try? JSONDecoder().decode(ChatStreamResponse.self, from: data),let content = chunk.choices.first?.delta.content{
                                continuation.yield(content)
                            }
                        }
                        if let httpResponse = response as? HTTPURLResponse {
                            print("====== 联调日志 ======")
                            print("HTTP 状态码: \(httpResponse.statusCode)") // 看看是 400, 401, 404 还是 500
                            
                            if !(200...299).contains(httpResponse.statusCode) {
                                // 打印出后端返回的错误 JSON，这通常包含具体的错误原因（比如模型不存在或鉴权失败）
                                if let errorString = String(data: Data(), encoding: .utf8) {
                                    print("后端报错详情: \(errorString)")
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                }catch{
                    continuation.finish(throwing: error)
                    
                }
            }
        
        }
    }
}
