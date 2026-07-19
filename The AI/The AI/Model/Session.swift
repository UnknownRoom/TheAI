//
//  Session.swift
//  The AI
//
//  Created by 梓墨 on 2026/4/22.
//

import Foundation

struct Session: Identifiable,Codable{
    
    let id: UUID
    var title = ""
    var messages: [Message]
}
