//
//  SetupStep.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/5/18.
//

import Foundation

enum SetupStep {
    case environment  // 第一步：下載環境、裝依賴
    case config       // 第二步：填寫 .env 密鑰配置
    case running      // 第三步：一鍵啟動與守護
}
