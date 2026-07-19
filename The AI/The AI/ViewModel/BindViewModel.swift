//
//  BandViewModel.swift
//  The AI
//
//  Created by 梓墨 on 2026/6/18.
//

import Foundation
import SwiftUI
import AppKit
import Combine

class BindViewModel:ObservableObject{
    @Published var channelIndex: Int = 0
    
    @Published var BaseURL: String = ""
    @Published var ModelName: String = ""
    @Published var APIKey: String = ""
    
    @Published var isSaving = false
    @Published var savingMessage = ""
    
    let siliconModels = [
        "deepseek-ai/DeepSeek-V3",
        "deepseek-ai/DeepSeek-R1",
        "Qwen/Qwen2.5-72B-Instruct",
        "THUDM/glm-4-9b-chat",
        "自定义"
    ]
    
}
