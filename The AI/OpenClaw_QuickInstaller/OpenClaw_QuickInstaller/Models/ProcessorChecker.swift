//
//  ProcessorChecker.swift
//  OpenClaw_QuickInstaller
//
//  Created by 梓墨 on 2026/6/9.
//

import Foundation

enum ProcessorArchitecture: String {
    case intel = "Intel (x86_64)"
    case appleSilicon = "Apple Silicon (arm64)"
    case unknown = "Unknown"
}

func detectCPUArchitecture() -> ProcessorArchitecture {
    // 1. 先检查当前进程是否运行在 Rosetta 2 转译环境下
    var isTranslated: Int32 = 0
    var size = MemoryLayout<Int32>.size
    
    // 如果 sysctl.proc_translated 返回 1，说明当前是 M系列芯片在模拟运行 Intel 应用
    if sysctlbyname("sysctl.proc_translated", &isTranslated, &size, nil, 0) == 0 {
        if isTranslated == 1 {
            return .appleSilicon
        }
    }
    
    // 2. 如果不是转译环境，检查真实的 CPU 类型
    var cpuType: cpu_type_t = 0
    var cpuTypeSize = MemoryLayout<cpu_type_t>.size
    
    if sysctlbyname("hw.cputype", &cpuType, &cpuTypeSize, nil, 0) == 0 {
        // CPU_TYPE_ARM64 在 Mach-O 头文件中的宏定义值
        if cpuType == (CPU_TYPE_ARM | CPU_ARCH_ABI64) || cpuType == 16777228 {
            return .appleSilicon
        } else if cpuType == (CPU_TYPE_X86 | CPU_ARCH_ABI64) || cpuType == 16777223 {
            return .intel
        }
    }
    
    return .unknown
}
