//
//  BindingView.swift
//  The AI
//

import SwiftUI

struct BindingView: View {
    @StateObject private var bandvm = BindViewModel.shared
    @State private var isKeyVisible = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    providerSection
                    connectionSection
                    securityNote
                }
                .padding(28)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            footer
        }
        .frame(minWidth: 620, idealWidth: 700, minHeight: 680, idealHeight: 760)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("连接模型服务")
                    .font(.system(size: 22, weight: .bold))
                Text("绑定 API Key 与服务地址，开始使用你选择的模型。")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("OpenAI 兼容接口", systemImage: "checkmark.circle.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.green.opacity(0.1), in: Capsule())
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("服务商", caption: "选择服务商以自动填入推荐地址和模型")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(LLMProvider.allCases) { provider in
                    providerCard(provider)
                }
            }

            Group {
                labeledField("Base URL", detail: "API 服务地址") {
                    TextField("https://api.example.com/v1", text: $bandvm.BaseURL)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                }

                labeledField("API Key", detail: "密钥会保存在这台 Mac 的钥匙串中") {
                    HStack(spacing: 8) {
                        Group {
                            if isKeyVisible {
                                TextField("粘贴 API Key", text: $bandvm.APIKey)
                            } else {
                                SecureField("粘贴 API Key", text: $bandvm.APIKey)
                            }
                        }
                        .textFieldStyle(.plain)
                        Button {
                            isKeyVisible.toggle()
                        } label: {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(isKeyVisible ? "隐藏 API Key" : "显示 API Key")
                    }
                }

                labeledField("模型名称", detail: "填写该服务商提供的模型 ID") {
                    HStack(spacing: 8) {
                        TextField("例如 deepseek-chat", text: $bandvm.ModelName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, design: .monospaced))
                        if !bandvm.providerModels.isEmpty {
                            Menu {
                                ForEach(bandvm.providerModels, id: \.self) { model in
                                    Button(model) { bandvm.ModelName = model }
                                }
                            } label: {
                                Label("推荐", systemImage: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07)))
    }

    private func providerCard(_ provider: LLMProvider) -> some View {
        let selected = bandvm.provider == provider
        return Button {
            bandvm.selectProvider(provider)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(selected ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.05))
                        .frame(width: 34, height: 34)
                    Image(systemName: providerIcon(provider))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(provider.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer(minLength: 0)
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                                .font(.system(size: 14))
                        }
                    }
                    Text(provider.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .background(selected ? Color.accentColor.opacity(0.055) : Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.08), lineWidth: selected ? 1.4 : 1))
        }
        .buttonStyle(.plain)
    }

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("连接测试", caption: "发送一条简短请求，确认地址、密钥和模型可以正常使用")
            HStack(spacing: 10) {
                Button {
                    Task { await bandvm.testConnection() }
                } label: {
                    HStack(spacing: 7) {
                        if bandvm.isTesting { ProgressView().controlSize(.small) }
                        else { Image(systemName: "bolt.horizontal.circle") }
                        Text(bandvm.isTesting ? "正在测试" : "测试连接")
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .disabled(bandvm.isTesting)

                if !bandvm.connectionMessage.isEmpty {
                    Label(bandvm.connectionMessage,
                          systemImage: bandvm.connectionSucceeded ? "checkmark.circle.fill" : (bandvm.isTesting ? "hourglass" : "exclamationmark.circle.fill"))
                        .font(.system(size: 12))
                        .foregroundStyle(bandvm.connectionSucceeded ? Color.green : (bandvm.isTesting ? Color.secondary : Color.orange))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07)))
    }

    private var securityNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("密钥仅保存在本机")
                    .font(.system(size: 12, weight: .semibold))
                Text("API Key 使用 macOS 钥匙串存储。请勿将密钥分享给他人。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if !bandvm.savingMessage.isEmpty {
                Label(bandvm.savingMessage,
                      systemImage: bandvm.savingMessage == "配置已安全保存" ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(bandvm.savingMessage == "配置已安全保存" ? Color.green : Color.orange)
            }
            Spacer()
            Button("取消") { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button {
                bandvm.save()
            } label: {
                Label("保存配置", systemImage: "checkmark")
                    .fontWeight(.semibold)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .top) { Divider() }
    }

    private func sectionTitle(_ title: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 15, weight: .bold))
            Text(caption).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private func labeledField<Content: View>(_ title: String, detail: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
            }
            HStack {
                content()
            }
            .padding(.horizontal, 11)
            .frame(height: 39)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.primary.opacity(0.11)))
        }
        .padding(.top, 7)
    }

    private func providerIcon(_ provider: LLMProvider) -> String {
        switch provider {
        case .deepSeek: return "sparkle"
        case .openAI: return "circle.hexagongrid.fill"
        case .siliconFlow: return "water.waves"
        case .openRouter: return "point.3.connected.trianglepath.dotted"
        case .moonshot: return "moon.stars.fill"
        case .qwen: return "cloud.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

#Preview {
    BindingView()
}
