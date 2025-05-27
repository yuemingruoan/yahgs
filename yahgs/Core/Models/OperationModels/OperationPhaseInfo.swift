//
//  OperationPhaseInfo.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/24.
//

import Foundation

/// 表示操作阶段的附加信息，用于 UI 展示进度卡片
public struct OperationInfo {
    /// 当前阶段的描述，例如 "正在移动文件"
    let description: String

    /// 当前进度百分比（0.0 ~ 1.0）
    let progress: Double
}
