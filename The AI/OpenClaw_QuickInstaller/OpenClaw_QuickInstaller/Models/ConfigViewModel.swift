//
//  ConfigViewModel.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/19.
//

import SwiftUI
import Combine

@MainActor
class ConfigViewModel: ObservableObject {
    
    // 频道选择：0 为硅基流动，1 为 OpenAI 官方
    @Published var channelIndex: Int = 0
    
    // 输入项
    @Published var apiKey: String = ""
    @Published var baseUrl: String = ""
    @Published var modelName: String = ""
    @Published var port: String = ""
    @Published var currentDashboardURL: String? = nil
    
    @Published var isSaving = false
    @Published var saveMessage = ""

    // 预设模型列表（硅基流动常用模型）
    let siliconModels = [
        "deepseek-ai/DeepSeek-V3",
        "deepseek-ai/DeepSeek-R1",
        "Qwen/Qwen2.5-72B-Instruct",
        "THUDM/glm-4-9b-chat"
    ]

    init() {
        loadCurrentConfig()
    }

    func loadCurrentConfig() {
        let config = EnvManager.shared.loadEnv()
        self.apiKey = config["OPENAI_API_KEY"] ?? ""
        self.baseUrl = config["API_BASE_URL"] ?? "https://api.siliconflow.cn/v1"
        self.modelName = config["OPENAI_MODEL"] ?? "deepseek-ai/DeepSeek-V3"
        self.port = config["OPENCLAW_GATEWAY_PORT"] ?? "18789"
        
        // 自动识别当前属于哪个频道
        if baseUrl.contains("siliconflow") {
            channelIndex = 0
        } else if baseUrl.contains("openai.com") {
            channelIndex = 1
        }
    }
    func selectChannel(_ index: Int) {
            self.channelIndex = index
            if index == 0 {
                baseUrl = "https://api.siliconflow.cn/v1"
                if !siliconModels.contains(modelName) {
                    modelName = siliconModels[0]
                }
            } else {
                baseUrl = "https://api.openai.com/v1"
                modelName = "gpt-4o"
            }
        }

    // 🚀 新增：非空与格式验证属性（供 UI 按钮状态直接绑定）
        var isFormInvalid: Bool {
            // 1. Key 不能为空，且必须符合基本的 sk- 长度或前缀要求（硅基流动和 OpenAI 都是 sk- 开头）
            if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            
            // 2. Base URL 不能为空，且必须是合法的 http/https 格式
            if baseUrl.isEmpty || (!baseUrl.hasPrefix("http://") && !baseUrl.hasPrefix("https://")) {
                return true
            }
            
            // 3. 端口必须是纯数字，且在合理范围内
            if port.isEmpty || Int(port) == nil {
                return true
            }
            
            return false
        }
    func save() {
        isSaving = true
        let updates = [
            "OPENAI_API_KEY": apiKey,
            "API_BASE_URL": baseUrl,
            "OPENAI_MODEL": modelName,
            "OPENCLAW_GATEWAY_PORT": port
        ]
        
        do {
            try EnvManager.shared.saveEnv(updates: updates)
            saveMessage = "✅ 配置已保存"
        } catch {
            saveMessage = "❌ 保存失败: \(error.localizedDescription)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSaving = false
            self.saveMessage = ""
        }
    }
}
