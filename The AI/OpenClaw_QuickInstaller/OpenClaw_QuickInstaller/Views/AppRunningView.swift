//
//  AppRunningView.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/19.
//

import SwiftUI

struct AppRunningView: View {
    // 强绑定我们写好的单例守护者
    @ObservedObject private var service = ServiceManager.shared
    
    // 临时从 .env 读取出来的运行端口号（用来生成本地调用链接）
    @State private var runningPort: String = "18789"
    @State private var isCopied: Bool = false
    
    var onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // 1. 顶部的状态与控制卡片
            GroupBox(label: Label("守护进程控制台", systemImage: "bolt.horizontal.stage.left.filled")) {
                HStack(spacing: 20) {
                    // 🟢/🔴 呼吸灯指示器
                    HStack(spacing: 8) {
                        Circle()
                            .fill(service.isRunning ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                            // 加上一个平滑的渐变呼吸动画
                            .shadow(color: service.isRunning ? .green : .red, radius: service.isRunning ? 4 : 1)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: service.isRunning)
                        
                        Text(service.isRunning ? "OpenClaw 运行中" : "服务已停止")
                            .font(.headline)
                    }
                    .frame(width: 150, alignment: .leading)
                    
                    Spacer()
                    
                    // 启停控制按钮
                    Button(action: {
                        if service.isRunning {
                            service.stopService()
                        } else {
                            service.startService()
                        }
                    }) {
                        Label(
                            service.isRunning ? "停止服务" : "启动服务",
                            systemImage: service.isRunning ? "stop.fill" : "play.fill"
                        )
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(service.isRunning ? .red : .accentColor)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 5)
            }
            
            // 2. 核心调用地址卡片（保姆级一键复制）
            if service.isRunning {
                GroupBox(label: Label("客户端配置指引", systemImage: "paperplane.fill")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("请将下方地址作为 Base URL 填入你的 Chatbox / NextChat / 沉浸式翻译等客户端中：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            let apiUrl = "http://127.0.0.1:\(runningPort)/v1"
                            
                            Text(apiUrl)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(4)
                            
                            Button(action: {
                                // 写入 macOS 剪贴板
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(apiUrl, forType: .string)
                                
                                isCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    isCopied = false
                                }
                            }) {
                                Label(isCopied ? "已复制" : "复制地址", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(isCopied ? .green : .accentColor)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // 3. 极简黑客风实时访问日志面板
            VStack(alignment: .leading, spacing: 6) {
                Label("实时转发日志流 (Live Traffic Log)", systemImage: "terminal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    ScrollViewReader { proxy in
                        Text(service.serviceLog)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .id("SERVICE_LOG_BOTTOM")
                            // 日志内容变动时自动锁死滚动到最底部
                            .onChange(of: service.serviceLog) { _, _ in
                                proxy.scrollTo("SERVICE_LOG_BOTTOM", anchor: .bottom)
                            }
                    }
                }
                .frame(height: 180)
                .background(Color(nsColor: .windowBackgroundColor)) // 贴合 macOS 暗黑/明亮系统色
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            HStack{
                Button("上一步", action: onBack)
                    .buttonStyle(.borderless)
                    .disabled(service.isRunning)
                Spacer()
            }
            
        }
        .padding()
        .onAppear {
            // 界面加载时，顺手捞一眼当前实际配在 .env 里的运行端口，以防不是默认值
            let config = EnvManager.shared.loadEnv()
            self.runningPort = config["OPENCLAW_GATEWAY_PORT"] ?? "18789"
            
            // 🚀 用户切到这一页时，自动帮他们拉起服务
            if !service.isRunning {
                service.startService()
            }
        }
    }
}

