//
//  MainInstallerView.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/17.
//

import SwiftUI

struct MainInstallerView:View {
    
    @State private var currentStep: SetupStep = .environment
    
    var body: some View {
        VStack {
            // 頂部可以做一个進度條指示器 (Step Indicator)
//            StepHeaderView(currentStep: currentStep)
            Divider()
            
            // 根據當前階段動態切換視圖
            switch currentStep {
                case .environment:
                    EnvironmentSetupView(onFinished: {
                        currentStep = .config}
                    )
                case .config:
                    EnvConfigView(
                        onBack: {
                            currentStep = .environment}
                        , onFinished: {
                            currentStep = .running}
                    )
                case .running:
                    AppRunningView(
                        onBack: {
                            currentStep = .config
                        }
                    )
            }
//            HStack{
//                Button{
//                    switch currentStep {
//                        case .running: currentStep = .config
//                        case .config: currentStep = .environment
//                        case .environment: break
//                    }
//                }label: {
//                    Text("上一步")
//                }
//                .disabled(currentStep == .environment)
//                
//                Button{
//                    switch currentStep {
//                        case .environment: currentStep = .config
//                        case .config: currentStep = .running
//                        case .running:
//
//                            print("安装完成")
//
//                        }
//                }label: {
//                    if currentStep != .running{
//                        Text("下一步")
//                    }else{
//                        Text("完成")
//                    }
//                }
//            }🤡
//
        }
        .frame(width: 550, height: 400)
        .padding()
    }
}
