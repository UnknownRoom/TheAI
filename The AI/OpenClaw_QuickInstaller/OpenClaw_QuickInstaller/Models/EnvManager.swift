//
//  EnvManager.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/18.
//

import Foundation


class EnvManager {
    static let shared = EnvManager()
    
    // 定位 OpenClaw 根目录下的 .env 文件路径
    private var envFileURL: URL {
        return NodeManager.shared.nodeDirURL.appendingPathComponent(".env")
    }
    
    /// 1. 从 .env 文件中解析出键值对
    func loadEnv() -> [String: String] {
        var config: [String: String] = [:]
        
        // 如果文件不存在，直接返回空字典
        guard FileManager.default.fileExists(atPath: envFileURL.path) else {
            return config
        }
        
        do {
            let content = try String(contentsOf: envFileURL, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                // 忽略空行和注释行
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                
                // 按第一个 "=" 分割键和值
                if let equalIndex = trimmed.firstIndex(of: "=") {
                    let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                    let value = String(trimmed[trimmed.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)
                    
                    // 去除可能存在的首尾单/双引号 (如 OPENAI_API_KEY="sk-xxx")
                    let sanitizedValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    config[key] = sanitizedValue
                }
            }
        } catch {
            print("⚠️ 读取 .env 失败: \(error.localizedDescription)")
        }
        
        return config
    }
    
    /// 2. 保存配置到 .env 文件（精准替换，保留注释）
    func saveEnv(updates: [String: String]) throws {
        let fileManager = FileManager.default
        
        // 如果文件压根不存在，直接进入极简创建模式
        if !fileManager.fileExists(atPath: envFileURL.path) {
            let content = updates.map { "\($0.key)=\($0.value)" }.joined(separator: "\n")
            try content.write(to: envFileURL, atomically: true, encoding: .utf8)
            print("📝 .env 文件不存在，已新建并写入成功。")
            return
        }
        
        // 如果文件存在，我们要读取它并进行精准行替换
        let currentContent = try String(contentsOf: envFileURL, encoding: .utf8)
        var lines = currentContent.components(separatedBy: .newlines)
        var updatedKeys = Set<String>()
        
        // 遍历现有文件的每一行
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if let equalIndex = trimmed.firstIndex(of: "=") {
                let key = String(trimmed[..<equalIndex]).trimmingCharacters(in: .whitespaces)
                
                // 如果这个 Key 在用户的待更新列表里，我们直接原位替换这一行
                if let newValue = updates[key] {
                    lines[index] = "\(key)=\(newValue)"
                    updatedKeys.insert(key)
                }
            }
        }
        
        // 检查有没有用户新加的、原文件中不存在的 Key
        for (key, value) in updates {
            if !updatedKeys.contains(key) {
                // 如果最后一行不是空行，先补一个换行
                if let last = lines.last, !last.trimmingCharacters(in: .whitespaces).isEmpty {
                    lines.append("")
                }
                lines.append("\(key)=\(value)")
            }
        }
        
        // 将合并修改后的行重新写回文件
        let finalContent = lines.joined(separator: "\n")
        try finalContent.write(to: envFileURL, atomically: true, encoding: .utf8)
        print("💾 .env 配置文件精准更新成功！")
    }
}
