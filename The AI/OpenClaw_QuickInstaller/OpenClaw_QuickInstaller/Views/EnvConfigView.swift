import SwiftUI

struct EnvConfigView: View {
    @StateObject private var vm = ConfigViewModel()
    var onBack: () -> Void
    var onFinished: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("配置 API 凭证")
                    .font(.title2).bold()
                Spacer()
                
                // 💡 核心优化：使用自定义 Binding 拦截点击，完美避开紫色警告
                Picker("", selection: Binding(
                    get: { vm.channelIndex },
                    set: { vm.selectChannel($0) } // 显式调用方法更新
                )) {
                    Text("🇨🇳 硅基流动 (推荐)").tag(0)
                    Text("🌐 OpenAI 官方").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            
            Form {
                GroupBox(label: Label("基础配置", systemImage: "key.fill")) {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        // API KEY 输入框
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("API Key:").frame(width: 80, alignment: .trailing)
                                SecureField("请填写以 sk- 开头的 API 密钥", text: $vm.apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    // 🚀 验证提示 1：如果为空，输入框边缘变红提示
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(vm.apiKey.isEmpty ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
                                    )
                                
                                if vm.channelIndex == 0 {
                                    Link("获取 Key", destination: URL(string: "https://cloud.siliconflow.cn/account/ak")!)
                                        .font(.caption)
                                }
                            }
                            // 🚀 验证提示 2：文字版弱提醒
                            if vm.apiKey.isEmpty {
                                Text("⚠️ API Key 不能为空，否则 OpenClaw 无法工作")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.leading, 88)
                            }
                        }
                        
                        // Base URL
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Base URL:").frame(width: 80, alignment: .trailing)
                                TextField("https://...", text: $vm.baseUrl)
                                    .textFieldStyle(.roundedBorder)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke((vm.baseUrl.isEmpty || !vm.baseUrl.hasPrefix("http")) ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
                                    )
                            }
                            if !vm.baseUrl.hasPrefix("http") && !vm.baseUrl.isEmpty {
                                Text("⚠️ 网址必须以 http:// 或 https:// 开头")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.leading, 88)
                            }
                        }
                    }
                    .padding(10)
                }
                
                GroupBox(label: Label("模型与端口", systemImage: "cpu")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("默认模型:").frame(width: 80, alignment: .trailing)
                            if vm.channelIndex == 0 {
                                Picker("", selection: $vm.modelName) {
                                    ForEach(vm.siliconModels, id: \.self) { model in
                                        Text(model).tag(model)
                                    }
                                }
                                .labelsHidden()
                            } else {
                                TextField("gpt-4o", text: $vm.modelName)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        // 端口号验证
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("运行端口:").frame(width: 80, alignment: .trailing)
                                TextField("", text: $vm.port)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Int(vm.port) == nil ? Color.red.opacity(0.7) : Color.clear, lineWidth: 1)
                                    )
                                Text("默认 18789").font(.caption).foregroundColor(.secondary)
                            }
                            if Int(vm.port) == nil && !vm.port.isEmpty {
                                Text("⚠️ 端口必须是纯数字（如 18789）")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(.leading, 88)
                            }
                        }
                    }
                    .padding(10)
                }
            }
            .formStyle(.grouped)
            
            // 底部按钮栏
            HStack(spacing: 15) {
                Button("上一步", action: onBack)
                    .buttonStyle(.borderless)
                
                Spacer()
                
                if !vm.saveMessage.isEmpty {
                    Text(vm.saveMessage)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                
                Button(action: {
                    vm.save()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        onFinished()
                    }
                }) {
                    Text("保存并进入下一步")
                        .padding(.horizontal, 10)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                // 🚀 核心拦截：如果表单验证不通过，按钮直接变灰禁用！
                .disabled(vm.isFormInvalid || vm.isSaving)
            }
        }
        .padding()
    }
}
