//
//  LauncherUpdater.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import Foundation

struct UpdateInfo {
    let version: String
    let releaseNotes: String?
    let downloadURL: URL
}

class LauncherUpdater {
    func checkForUpdates() async throws -> UpdateInfo? {
        // 未来实现 GitHub Release 或其他服务器接口请求
        return nil
    }

    func performUpdate(with info: UpdateInfo) async throws {
        // 未来实现更新下载和安装逻辑
    }
}
