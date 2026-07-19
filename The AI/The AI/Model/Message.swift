//
//  Message.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import Foundation

struct Message: Identifiable,Codable{//Codable协议执行“全家桶”原则 要求其内部的属性均为Codable
    
    var id = UUID()
    
    let role: Role
    var content: String
    var isGenerating:Bool = Bool()
    var timestamp: Date = Date()
    
    enum CodingKeys: String,CodingKey {
        case role
        case content
    
    }
}
enum Role: String,Codable{
    case system = "system"
    case user = "user"
    case assistant = "assistant"
}
