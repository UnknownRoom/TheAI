//
//  ServiceManager.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/20.
//

import Foundation
import Combine
import AppKit
import SwiftUI

class ServiceManager: ObservableObject {
    static let shared = ServiceManager()
    @ObservedObject private var cfgvm = ConfigViewModel()
    
    // 供 UI 绑定的发布者状态
    @Published var isRunning: Bool = false
    @Published var serviceLog: String = ""
    
    // 内部持有的长线运行进程和管道
    private var activeProcess: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var logTask: Task<Void, Never>?
    
    private init() {
        //  核心安全锁：注册系统通知，当 App 被用户关闭时，强制触发杀进程逻辑，绝不留僵尸
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    ///  启动 OpenClaw 后台服务
        
            func setupOpenClawPhysicalConfig(targetPort: Int) {
                let fileManager = FileManager.default
                let homeDir = fileManager.homeDirectoryForCurrentUser
                
                // ~/.openclaw/ 根目录
                let openClawURL = homeDir.appendingPathComponent(".openclaw")
                let agentDirURL = openClawURL.appendingPathComponent("agents").appendingPathComponent("main")
                let sessionsDirURL = agentDirURL.appendingPathComponent("sessions")
                
                do {
                    // 确保文件夹全部存在
                    try fileManager.createDirectory(at: sessionsDirURL, withIntermediateDirectories: true, attributes: nil)
                    
                    // 1. 在全局根目录下写入主配置文件
                    let globalConfigFileURL = openClawURL.appendingPathComponent("openclaw.json")

                    // 从用户配置中读取模型信息
                    let userAPIKey = cfgvm.apiKey
                    let userBaseURL = cfgvm.baseUrl
                    let userModelName = cfgvm.modelName

                    // 区分内置 provider（OpenAI）与自定义 provider（硅基流动等）
                    let isOpenAI = userBaseURL.contains("openai.com")

                    let globalConfigContent: String
                    if isOpenAI {
                        // OpenAI 是 OpenClaw 内置 provider，无需 models.providers 配置
                        // 只需设 agents.defaults.model.primary，API key 由 .env 中的 OPENAI_API_KEY 提供
                        globalConfigContent = """
                        {
                          "gateway": {
                            "mode": "local",
                            "port": \(targetPort),
                            "auth": {
                              "mode": "none"
                            }
                          },
                          "agents": {
                            "defaults": {
                              "model": {
                                "primary": "openai/\(userModelName)"
                              }
                            }
                          }
                        }
                        """
                    } else {
                        // 自定义 provider（硅基流动等）—— 需要完整的 models.providers 声明
                        globalConfigContent = """
                        {
                          "gateway": {
                            "mode": "local",
                            "port": \(targetPort),
                            "auth": {
                              "mode": "none"
                            }
                          },
                          "models": {
                            "providers": {
                              "custom": {
                                "baseUrl": "\(userBaseURL)",
                                "apiKey": "\(userAPIKey)",
                                "api": "openai-completions",
                                "models": [
                                  {
                                    "id": "\(userModelName)",
                                    "name": "\(userModelName)"
                                  }
                                ]
                              }
                            }
                          },
                          "agents": {
                            "defaults": {
                              "model": {
                                "primary": "custom/\(userModelName)"
                              }
                            }
                          }
                        }
                        """
                    }

                    // 2. 同时在 agent 目录下也复制一份
                    let agentConfigFileURL = agentDirURL.appendingPathComponent("openclaw.json")

                    // 总是覆盖写入，确保配置始终是最新的
                    try globalConfigContent.write(to: globalConfigFileURL, atomically: true, encoding: .utf8)

                    try globalConfigContent.write(to: agentConfigFileURL, atomically: true, encoding: .utf8)


                    // 3. 写入 sessions.json（历史兼容，OpenClaw 实际不读取此文件）
                    let sessionsFileURL = sessionsDirURL.appendingPathComponent("sessions.json")
                    let sessionsContent = """
                    {
                      "active": true,
                      "default_model": "\(userModelName)",
                      "models": {
                        "\(userModelName)": {
                          "provider": "\(isOpenAI ? "openai" : "custom")",
                          "api_key": "\(userAPIKey)",
                          "base_url": "\(userBaseURL)"
                        }
                      }
                    }
                    """
                    try sessionsContent.write(to: sessionsFileURL, atomically: true, encoding: .utf8)

                    print("📝 [Swift Core] 配置写入成功，端口: \(targetPort)，模型: \(isOpenAI ? "openai" : "custom")/\(userModelName)")

                } catch {
                    print("🚨 动态写入配置失败: \(error)")
                }
            }
        func startService() {
            
            let currentPort = Int(cfgvm.port) ?? 18789
            setupOpenClawPhysicalConfig(targetPort: currentPort)
            
            guard !isRunning && activeProcess == nil else { return }
            
            DispatchQueue.main.async {
                self.serviceLog = "🤖 正在初始化 OpenClaw 后台守护进程...\n"
            }
            
            let process = Process()
            self.activeProcess = process
            process.executableURL = NodeManager.shared.nodeExecutableURL
            
            // 💡 确保你的相对路径在 node_modules 里是完全吻合的

            // 修正：直接指向最新版 OpenClaw 的 dist/index.js 入口
            
            let nodejsDirURL = NodeManager.shared.nodeDirURL

            // 1. 我们刚刚创建的环境伪装芯片路径
            let serverLauncherURL = nodejsDirURL.appendingPathComponent("server.js")

            // 2. OpenClaw 真正的 CLI 常驻入口
            let openClawEntryURL = nodejsDirURL
                .appendingPathComponent("node_modules")
                .appendingPathComponent("openclaw")
                .appendingPathComponent("dist")
                .appendingPathComponent("index.js")
            
            

            process.arguments = [
                "--import", "file://\(serverLauncherURL.path)", // 预加载我们的垫片
                openClawEntryURL.path,                          // 核心入口
                "gateway",
                "--allow-unconfigured",
            ]

            process.currentDirectoryURL = nodejsDirURL

            // 基础 PATH 环境变量拼接保持不变
            var env = ProcessInfo.processInfo.environment
            let nodeBinDirPath = NodeManager.shared.nodeExecutableURL.deletingLastPathComponent().path
            env["PATH"] = env["PATH"] != nil ? "\(nodeBinDirPath):\(env["PATH"]!)" : nodeBinDirPath
            env["NODE_OPTIONS"] = "--dns-result-order=ipv4first"

            // 順便確保環境變數裡也有雙重保險
            env["PORT"] = String(currentPort)
            env["HOST"] = "127.0.0.1"
            env["SWIFT_API_KEY"] = self.cfgvm.apiKey
            
            env["DEBUG"] = "*"
            env["NODE_DEBUG"] = "net,http,stream"
//            env["CI"] = "true"
            
            let localProxyPort = "7892"
            
            env["HTTP_PROXY"] = "http://127.0.0.1:\(localProxyPort)"
            env["HTTPS_PROXY"] = "http://127.0.0.1:\(localProxyPort)"
            
            env["NO_PROXY"] = "127.0.0.1,localhost"
            
            process.environment = env
            
            let outPipe = Pipe()
            let errPipe = Pipe()
            self.outputPipe = outPipe
            self.errorPipe = errPipe
            
            process.standardOutput = outPipe
            process.standardError = errPipe
            
//            self.outputPipe = pipe
//            self.activeProcess = process
            
            // 🚀 【核心修复】改为优雅的基于闭包的数据读取器，彻底废除 while 循环和 availableData
            outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                
                if let output = String(data: data, encoding: .utf8) {
                    print("🟢 [OpenClaw STDOUT]: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
                    if output.contains("http://127.0.0.1") || output.contains("token=") {
                                // 抓到了！提取出这一行完整的 URL
                                if let detectedURL = self?.extractURL(from: output) {
                                    DispatchQueue.main.async {
                                        
                                        self?.cfgvm.currentDashboardURL = detectedURL
                                        print("🔑 [Swift Core] 绝密动态令牌拦截成功！！链接为: \(detectedURL)")
                                    }
                                }
                            }
                    DispatchQueue.main.async {
                        self?.serviceLog += output
                    }
                }
            }
            errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
                        let data = handle.availableData
                        guard !data.isEmpty else { return }
                        if let errorOutput = String(data: data, encoding: .utf8) {
                            // 🔴 实时喷射到 Xcode 控制台
                            print("🔴 [OpenClaw STDERR]: \(errorOutput.trimmingCharacters(in: .whitespacesAndNewlines))")
                        }
                    }
            process.terminationHandler = { [weak self] p in
                        print("🎬 [Swift] 后台进程宣告结束。状态码: \(p.terminationStatus)")
                        self?.cleanupPipes()
                    }
            do {
                // 此时安全地拉起进程
                try process.run()
                
                DispatchQueue.main.async {
                    self.isRunning = true
                    self.serviceLog += "🟢 OpenClaw 进程已成功拉起，开始监听端口...\n"
                }
                
                process.terminationHandler = { [weak self] proc in
                    guard let self = self else { return }
                    print("🤖 后台进程宣告结束。状态码: \(proc.terminationStatus)")
                    self.cleanUpResources()
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.serviceLog += "❌ 进程拉起瞬间失败: \(error.localizedDescription)\n"
                }
                cleanupPipes()
                cleanUpResources()
            }
        }
    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        if let match = matches?.first, let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }
        
        /// 🧹 内存与状态大扫除（同步更新）
        private func cleanUpResources() {
            // 🚀 必须把 readabilityHandler 置为空，彻底关闭监听管道
            outputPipe?.fileHandleForReading.readabilityHandler = nil
            try? outputPipe?.fileHandleForReading.close()
            
            outputPipe = nil
            activeProcess = nil
            
            DispatchQueue.main.async {
                if self.isRunning {
                    self.isRunning = false
                    self.serviceLog += "🔴 OpenClaw 服务已完全停止，端口已安全释放。\n"
                }
            }
        }
    /// 🛑 停止 OpenClaw 后台服务
    func stopService() {
        guard let process = activeProcess, process.isRunning else {
            cleanUpResources()
            return
        }
        
        DispatchQueue.main.async {
            self.serviceLog += "\n🛑 正在向后台进程发送终止信号...\n"
        }
        
        process.terminate() // 优雅终止信号 (SIGTERM)
        process.waitUntilExit() // 死死等它彻底退出，释放端口
        
        cleanUpResources()
    }
    
    /// 📥 后台高能管道吸雾器：实时榨取终端日志
    private func startLoggingTask(readHandle: FileHandle) {
        logTask = Task.detached(priority: .background) {
            // 只要进程活着，或者管道里还有没吐完的水，就一直读
            while !Task.isCancelled {
                let data = readHandle.availableData
                if !data.isEmpty {
                    if let output = String(data: data, encoding: .utf8) {
                        await MainActor.run {
                            // 实时追加到 UI 绑定的字符串中
                            ServiceManager.shared.serviceLog += output
                        }
                    }
                } else {
                    // 没有数据时略微休息，防止死循环导致单核 CPU 飙满 100%
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
                }
                
                // 检查进程如果死了，且数据已经读空，主动跳出
                if let proc = await ServiceManager.shared.activeProcess, !proc.isRunning {
                    break
                }
            }
        }
    }
    /// 🍏 联动防线：当用户点击 Mac 左上角关闭 App、或者 Cmd+Q 闪人时，底层强制收尾
    @objc private func handleAppWillTerminate() {
        print("🚨 检测到 App 即将退出，正在强制清理后台 OpenClaw 服务...")
        if let process = activeProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
    }
    private func cleanupPipes() {
            self.outputPipe?.fileHandleForReading.readabilityHandler = nil
            self.errorPipe?.fileHandleForReading.readabilityHandler = nil
            self.outputPipe = nil
            self.errorPipe = nil
        }
}

