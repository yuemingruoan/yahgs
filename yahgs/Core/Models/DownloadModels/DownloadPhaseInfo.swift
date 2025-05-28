//
//  DownloadPhaseInfo.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//



import Foundation

/// 下载任务附加信息：显示在 ProgressViewCard 上
struct DownloadInfo {
    /// 当前已下载大小（格式化后的文本，例如 "32.5 MiB"）
    let downloadedSize: String

    /// 总文件大小（格式化后的文本，例如 "120 MiB"）
    let totalSize: String

    /// 当前下载速率（格式化后的文本，例如 "3.1 MiB/s"）
    let speed: String    
}
