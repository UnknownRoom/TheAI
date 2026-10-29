//
//  BindViewModel.swift
//  The AI
//

import Foundation
import Combine
import Security

enum LLMProvider: String, CaseIterable, Identifiable {
    case deepSeek = "DeepSeek"
    case openAI = "OpenAI / ChatGPT"
    case siliconFlow = "SiliconFlow"
    case openRouter = "OpenRouter"
    case moonshot = "Moonshot / Kimi"
    case qwen = "通义千问"
    case custom = "自定义服务"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .openAI: return "https://api.openai.com/v1"
        case .siliconFlow: return "https://api.siliconflow.cn/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        case .moonshot: return "https://api.moonshot.cn/v1"
        case .qwen: return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .custom: return ""
        }
    }

    var models: [String] {
        switch self {
        case .deepSeek: return ["deepseek-chat", "deepseek-reasoner"]
        case .openAI: return ["gpt-4o-mini", "gpt-4o", "gpt-4.1", "o3-mini"]
        case .siliconFlow: return ["deepseek-ai/DeepSeek-V3", "deepseek-ai/DeepSeek-R1", "Qwen/Qwen2.5-72B-Instruct"]
        case .openRouter: return ["openai/gpt-4o-mini", "anthropic/claude-3.7-sonnet", "deepseek/deepseek-chat-v3-0324"]
        case .moonshot: return ["kimi-k2-0711-preview", "moonshot-v1-8k", "moonshot-v1-32k"]
        case .qwen: return ["qwen-plus", "qwen-turbo", "qwen-max"]
        case .custom: return []
        }
    }

    var subtitle: String {
        switch self {
        case .deepSeek: return "DeepSeek 官方 API，支持对话与推理模型"
        case .openAI: return "OpenAI API，可使用 GPT 系列模型"
        case .siliconFlow: return "聚合多家开源模型，兼容 OpenAI 接口"
        case .openRouter: return "一个 Key 接入多家模型服务"
        case .moonshot: return "月之暗面 Kimi API"
        case .qwen: return "阿里云百炼 OpenAI 兼容接口"
        case .custom: return "填写任何兼容 OpenAI Chat Completions 的服务"
        }
    }
}

final class BindViewModel: ObservableObject {
    static let shared = BindViewModel()

    @Published var provider: LLMProvider = .deepSeek
    @Published var BaseURL = "https://api.deepseek.com/v1"
    @Published var ModelName = "deepseek-chat"
    @Published var APIKey = ""
    @Published var isSaving = false
    @Published var savingMessage = ""
    @Published var isTesting = false
    @Published var connectionMessage = ""
    @Published var connectionSucceeded = false

    private let defaults = UserDefaults.standard
    private let keychain = APIKeychain(service: "com.theai.llm")

    private init() {
        if let savedProvider = defaults.string(forKey: "llm.provider"),
           let provider = LLMProvider(rawValue: savedProvider) {
            self.provider = provider
        }
        BaseURL = defaults.string(forKey: "llm.baseURL") ?? provider.baseURL
        ModelName = defaults.string(forKey: "llm.model") ?? provider.models.first ?? ""
        APIKey = keychain.read() ?? ""
    }

    var channelIndex: Int { LLMProvider.allCases.firstIndex(of: provider) ?? 0 }
    var providerModels: [String] { provider.models }

    func selectProvider(_ newProvider: LLMProvider) {
        provider = newProvider
        guard newProvider != .custom else { return }
        BaseURL = newProvider.baseURL
        ModelName = newProvider.models.first ?? ""
        connectionMessage = ""
    }

    func save() {
        let normalizedURL = BaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedURL.isEmpty, URL(string: normalizedURL) != nil else {
            savingMessage = "请填写有效的 Base URL"
            return
        }
        guard !ModelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            savingMessage = "请填写模型名称"
            return
        }
        do {
            try keychain.write(APIKey)
            defaults.set(provider.rawValue, forKey: "llm.provider")
            defaults.set(normalizedURL, forKey: "llm.baseURL")
            defaults.set(ModelName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "llm.model")
            BaseURL = normalizedURL
            ModelName = ModelName.trimmingCharacters(in: .whitespacesAndNewlines)
            savingMessage = "配置已安全保存"
        } catch {
            savingMessage = "保存失败：\(error.localizedDescription)"
        }
    }

    func testConnection() async {
        guard !APIKey.isEmpty else {
            connectionSucceeded = false
            connectionMessage = "请先填写 API Key"
            return
        }
        guard let url = chatCompletionsURL(from: BaseURL) else {
            connectionSucceeded = false
            connectionMessage = "Base URL 格式无效"
            return
        }

        isTesting = true
        connectionMessage = "正在连接…"
        defer { isTesting = false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 25
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": ModelName,
            "messages": [["role": "user", "content": "Reply with OK" ]],
            "stream": false,
            "max_tokens": 8
        ])

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                connectionSucceeded = false
                connectionMessage = "服务没有返回有效响应"
                return
            }
            connectionSucceeded = (200...299).contains(response.statusCode)
            connectionMessage = connectionSucceeded
                ? "连接成功，API Key 与模型可用"
                : "连接失败（HTTP \(response.statusCode)），请检查 Key、模型和地址"
        } catch {
            connectionSucceeded = false
            connectionMessage = "连接失败：\(error.localizedDescription)"
        }
    }
}

func chatCompletionsURL(from baseURL: String) -> URL? {
    let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard var components = URLComponents(string: trimmed),
          let scheme = components.scheme,
          ["https", "http"].contains(scheme.lowercased()),
          components.host != nil else { return nil }
    let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    if !path.hasSuffix("chat/completions") {
        components.path = "/" + [path, "chat/completions"].filter { !$0.isEmpty }.joined(separator: "/")
    }
    return components.url
}

private struct APIKeychain {
    let service: String
    private let account = "provider-api-key"

    func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func write(_ value: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let data = Data(value.utf8)
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            let insertStatus = SecItemAdd(insert as CFDictionary, nil)
            guard insertStatus == errSecSuccess else { throw KeychainError(status: insertStatus) }
        } else if status != errSecSuccess {
            throw KeychainError(status: status)
        }
    }
}

private struct KeychainError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "Keychain 错误（\(status)）" }
}
