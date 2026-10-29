//
//  NodeEnvironmentManager.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/16.
//

import Foundation

class NodeManager {
    static let shared = NodeManager()
    let userCPU = detectCPUArchitecture()
    
    // 获取隔离环境的存放目录：~/Library/Application Support/YourApp/nodejs/
    var nodeDirURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("OpenClawManager", isDirectory: true)
        return appSupportDir.appendingPathComponent("nodejs", isDirectory: true)
    }
    
    // 绿色版 node 二进制文件的绝对路径
    var nodeExecutableURL: URL {
        if userCPU == .appleSilicon {
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-arm64/bin/node")
        }else if userCPU == .intel{
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-x64/bin/node")
        }else{
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-arm64/bin/node")
        }

        
    }
    var npmExecutableURL: URL {
        if userCPU == .appleSilicon {
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-arm64/bin/npm")
        }else if userCPU == .intel{
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-x64/bin/npm")
        }else{
            return
                nodeDirURL.appendingPathComponent("node-v22.17.0-darwin-arm64/bin/npm")
        }
    }
   
}
extension NodeManager {
    func setupNodeEnvironment(onProgress: @escaping (String) -> Void) async throws {
        let fileManager = FileManager.default

        // 1. 建立目錄
        if !fileManager.fileExists(atPath: nodeDirURL.path) {
            try fileManager.createDirectory(at: nodeDirURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // 2. 檢測是否已經安裝過（檢查關鍵二進位檔案是否存在）
        if fileManager.fileExists(atPath: nodeExecutableURL.path) {
            onProgress("✅ 綠色版 Node.js 環境已存在，跳過下載。")
            return
        }
        onProgress("🤔 处理器架构检查为...\(userCPU)")
        onProgress("🌐 正在從國內加速源下載对应版本的 Node.js v22...")
        
        // 根據架構選擇 URL
        var downloadURL: String{
            if userCPU == .appleSilicon{
                return "https://mirrors.cloud.tencent.com/nodejs-release/v22.17.0/node-v22.17.0-darwin-arm64.tar.gz"
            }else if userCPU == .intel{
                return
                    "https://mirrors.cloud.tencent.com/nodejs-release/v22.17.0/node-v22.17.0-darwin-x64.tar.gz"
            }else{
                return "https://mirrors.cloud.tencent.com/nodejs-release/v22.17.0/node-v22.17.0-darwin-arm64.tar.gz"
            }
        }
        let tarURL = nodeDirURL.appendingPathComponent("node.tar.gz")
        let tarPath = tarURL.path
        
        // 確保下載前舊的殘留壓縮包被清理乾淨
        if fileManager.fileExists(atPath: tarPath) {
            try? fileManager.removeItem(atPath: tarPath)
        }
        
        // 3. 使用 Swift Process 調用底層 curl 下載
        let curlProcess = Process()
        curlProcess.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        // -f: 錯誤時不輸出 HTML, -s: 靜音模式, -S: 顯示錯誤, -L: 跟隨重定向
        curlProcess.arguments = ["-fsSL", downloadURL, "-o", tarPath]
        
        try curlProcess.run()
        curlProcess.waitUntilExit()
        
        // 檢查 curl 是否成功執行
        if curlProcess.terminationStatus != 0 {
            throw NSError(domain: "NodeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "curl 下載失敗，請檢查網路連接。"])
        }
        
        onProgress("📦 下載完成，正在解壓到隔離目錄...")
        
        // 4. 調用 tar 解壓
        let tarProcess = Process()
        tarProcess.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        tarProcess.arguments = ["-f", tarPath, "-x", "-C", nodeDirURL.path]
        try tarProcess.run()
        tarProcess.waitUntilExit()
        
        // 檢查 tar 是否解壓成功
        if tarProcess.terminationStatus != 0 {
            throw NSError(domain: "NodeManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "tar 解壓失敗，壓縮包可能損壞。"])
        }
        
        // 5. 安全刪除 tar 壓縮包
        onProgress("🧹 正在清理臨時下載檔案...")
        
        // 💡 關鍵優化：解壓完成後，稍微等待 0.5 秒，確保檔案系統的寫入句柄（Handle）已完全釋放
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if fileManager.fileExists(atPath: tarPath) {
            do {
                try fileManager.removeItem(atPath: tarPath)
                onProgress("🎉 Node.js 隔離環境配置成功！")
            } catch {
                // 如果還是刪除失敗，不拋出致命異常，僅列印日誌，因為 node 已經解壓成功，不影響使用
                print("⚠️ 臨時壓縮包刪除失敗（可能被系統鎖定）: \(error.localizedDescription)")
                onProgress("🎉 Node.js 環境已就緒（臨時檔案將在下次啟動時自動清理）。")
            }
        } else {
            onProgress("🎉 Node.js 隔離環境配置成功！")
        }
    }
}
extension NodeManager {
    func runNpmCommand(arguments: [String], currentDirectory: URL, onStdout: @escaping (String) -> Void) throws {
            let process = Process()
            process.executableURL = nodeExecutableURL
            
            let nodeDir = nodeExecutableURL.deletingLastPathComponent().deletingLastPathComponent()
            let npmCliURL = nodeDir.appendingPathComponent("lib/node_modules/npm/bin/npm-cli.js")
            
            var finalArguments = [npmCliURL.path] + arguments
            finalArguments += ["--registry=https://registry.npmmirror.com"]
            
            process.arguments = finalArguments
            process.currentDirectoryURL = currentDirectory
            
            var env = ProcessInfo.processInfo.environment
            let nodeBinDirPath = nodeExecutableURL.deletingLastPathComponent().path
            if let currentPath = env["PATH"] {
                env["PATH"] = "\(nodeBinDirPath):\(currentPath)"
            } else {
                env["PATH"] = nodeBinDirPath
            }
            process.environment = env
            
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = outputPipe
            
            let readHandle = outputPipe.fileHandleForReading
            
            try process.run()
            
            var shouldForceExit = false
            
        while process.isRunning && !shouldForceExit {
                    let data = readHandle.availableData
                    if !data.isEmpty {
                        if let output = String(data: data, encoding: .utf8) {
                            DispatchQueue.main.async {
                                onStdout(output)
                            }
                            
                            // 🚀 升级版强行破门：只要包含以下任意一个 NPM 大结局关键字，立刻收工！
                            let lowercasedOutput = output.lowercased()
                            if lowercasedOutput.contains("up to date") ||
                               lowercasedOutput.contains("added") ||
                               lowercasedOutput.contains("audited") ||
                               lowercasedOutput.contains("funding") || // 👈 新增：捕获募捐提示
                               lowercasedOutput.contains("vulnerabilities") { // 👈 新增：捕获安全漏洞提示
                                
                                print("🤖 抓到 NPM 完工大结局关键字，准备强制断开...")
                                shouldForceExit = true
                            }
                        }
                    } else {
                        Thread.sleep(forTimeInterval: 0.01)
                    }
                }
            
            // 🚀 【核心修复】优雅地强杀并等待
            if process.isRunning {
                process.terminate() // 发送强杀信号
                process.waitUntilExit() // 🛑 关键：必须死死等它彻底退出！
                print("🤖 进程已被 Swift 强行终止成功。")
            } else {
                process.waitUntilExit() // 正常情况下也等一下，确保状态同步
                print("🤖 进程自然退出成功。")
            }
            
            // 残留数据清理
            if let remainingData = try? readHandle.readToEnd(), !remainingData.isEmpty {
                if let output = String(data: remainingData, encoding: .utf8) {
                    DispatchQueue.main.async {
                        onStdout(output)
                    }
                }
            }
            
            try? readHandle.close()
            
            // 此时读取 terminationStatus 绝对安全，再也不会崩溃
            print("🤖 Node 进程生命周期结束。状态码: \(process.terminationStatus)")
            
            // 如果是我们主动强杀的，状态码通常是 15 (SIGTERM)，可以判定为成功
            if process.terminationStatus != 0 && process.terminationStatus != 15 {
                throw NSError(domain: "NodeManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "NPM 命令执行失败，错误码: \(process.terminationStatus)"])
            }
        }
    }
