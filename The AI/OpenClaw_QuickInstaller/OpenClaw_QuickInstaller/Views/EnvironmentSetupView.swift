//
//  SetupView.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/16.
//

import SwiftUI

struct EnvironmentSetupView: View {
    
    @State private var logOutput: String = "等待初始化...\n"
    @State private var isRunning = false
    
    var onFinished: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("OpenClaw 环境一键配置")
                .font(.title)
                .bold()
            
            ScrollView {
                Text(logOutput)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 200)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
            
            Button(action: {
                isRunning = true
                Task {
                    do {
                        // 1. 配置绿色 Node 环境
                        try await NodeManager.shared.setupNodeEnvironment { progress in
                            logOutput += progress + "\n"
                        }
                        
                        // 2. 模拟在 OpenClaw 的安装目录下执行 npm install
                        let mockAppDir = NodeManager.shared.nodeDirURL
                        logOutput += "🚀 开始安装 OpenClaw 依赖...\n"
                        
                        try NodeManager.shared.runNpmCommand(arguments: ["install", "openclaw"], currentDirectory: mockAppDir) { npmLog in
                            logOutput += npmLog
                        }
                        
                        // 🌟 【核心优化】当上面所有流程毫无阻碍地跑完后，追加终极完成提示：
                        logOutput += """
                        
                        ==================================================
                        🎉 恭喜！第一阶段：Environment Setup（环境准备）已全部完成！
                        ==================================================
                        ✅ 隔离版 Node.js 引擎部署成功
                        ✅ OpenClaw 核心依赖包下载并检查完毕
                        
                        🤖 基础运行环境已就绪，正在准备进入下一步配置...
                        """
                        await MainActor.run {
                            onFinished()
                        }
                    } catch {
                        logOutput += "\n❌ 出错了: \(error.localizedDescription)\n"
                    }
                    isRunning = false
                }
            }) {
                Text(isRunning ? "正在配置..." : "开始一键配置")
            }
            .disabled(isRunning)
        }
        .padding()
        .frame(width: 500, height: 350)
    }
}
