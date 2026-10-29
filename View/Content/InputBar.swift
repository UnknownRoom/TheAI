//
//  InputCell.swift
//  The AI
//
//  Created by 梓墨 on 2026/3/12.
//

import SwiftUI

struct InputBar: View {
    
    @Binding var prompt: String
    var onSend: () -> Void
    @StateObject private var bindvm = BindViewModel.shared
    
    var body: some View {
        HStack{
            ZStack(alignment: .topLeading) {
                // 1. 底层背景
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3))
                    )
                
                // 2. 占位符 (手动处理，避免 TextEditor 遮挡)
                if prompt.isEmpty {
                    Text("给AI发送消息")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10) // 这里的数值要和 TextEditor 的位置对齐
                        .allowsHitTesting(false)
                }
                
                // 3. 核心输入组件
                    TextEditor(text: $prompt)
                        .font(.system(size: 14))    // 显式指定字体大小，方便计算高度
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 10)
                        .frame(minHeight: 60, maxHeight: 120)
                        .onEnterPerform {
                            onSend()
                        }

                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Menu {
                                ForEach(bindvm.providerModels, id: \.self) { model in
                                    Button(model) { bindvm.ModelName = model }
                                }
                            } label: {
                                Label(bindvm.ModelName.isEmpty ? "模型" : bindvm.ModelName, systemImage: "chevron.down")
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .disabled(bindvm.providerModels.isEmpty)
                            Button{
                                onSend()
                            }label: {
                                Image(systemName: "paperplane.fill")
                            }
                        }
                        .padding()
                    }
            }
            .padding(.horizontal) // 真正的外部间距放在这里
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

