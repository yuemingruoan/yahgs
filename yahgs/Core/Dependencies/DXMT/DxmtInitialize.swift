//
//  DxmtInitialize.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation
import Zip

public struct DxmtInitializer {
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
    }

    // 递归扁平化目录，复制所有 dll 和 so 文件到 dxmtURL 根目录
    private func flattenDXMTDirectory(at dxmtURL: URL) throws {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: dxmtURL, includingPropertiesForKeys: nil)

        for item in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let subContents = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil)
                for file in subContents {
                    let ext = file.pathExtension.lowercased()
                    if ext == "dll" || ext == "so" {
                        let destURL = dxmtURL.appendingPathComponent(file.lastPathComponent)
                        if fileManager.fileExists(atPath: destURL.path) {
                            try fileManager.removeItem(at: destURL)
                        }
                        try fileManager.copyItem(at: file, to: destURL)
                    }
                }
                try fileManager.removeItem(at: item)
            }
        }
    }

    // 初始化过程（异步）
    public func initialize(progressUpdate: @escaping (String, Double) -> Void) async throws {
        let fileManager = FileManager.default
        let containerDataURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")

        let dxmtURL = containerDataURL.appendingPathComponent("dxmt")
        // 检查 dxmt 目录是否存在且非空，若是则跳过初始化
        if fileManager.fileExists(atPath: dxmtURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: dxmtURL, includingPropertiesForKeys: nil)
            if !contents.isEmpty {
                progressUpdate("已有初始化，跳过", 1.0)
                return
            }
        }

        progressUpdate("开始初始化", 0.0)

        // 临时 .app 目录路径，指向 Wine Devel.app（可与 Wine 共享）
        let tempAppURL = containerDataURL.appendingPathComponent("Wine Devel.app")

        // 如果存在旧的 dxmt 目录，先删除
        if fileManager.fileExists(atPath: dxmtURL.path) {
            try fileManager.removeItem(at: dxmtURL)
        }
        progressUpdate("删除旧目录", 0.1)

        // 将 Wine Devel.app/Contents/Resources/dxmt 移动到 Application Support 的 dxmt 目录
        let dxmtSourceURL = tempAppURL.appendingPathComponent("Contents/Resources/dxmt")
        if fileManager.fileExists(atPath: dxmtSourceURL.path) {
            try fileManager.moveItem(at: dxmtSourceURL, to: dxmtURL)
        }
        progressUpdate("移动资源文件", 0.3)

        // 删除临时 .app 解压目录
        if fileManager.fileExists(atPath: tempAppURL.path) {
            try fileManager.removeItem(at: tempAppURL)
        }
        progressUpdate("删除临时文件", 0.5)

        // --- 将 dxmt 内容同步复制到 gameprefix ---
        let gamePrefixPath = containerDataURL.appendingPathComponent("gameprefix")
        let system32Path = gamePrefixPath.appendingPathComponent("drive_c/windows/system32")
        try fileManager.createDirectory(at: system32Path, withIntermediateDirectories: true)
        progressUpdate("创建游戏目录", 0.55)

        let dxmtFiles = try fileManager.contentsOfDirectory(at: dxmtURL, includingPropertiesForKeys: nil)
        for file in dxmtFiles {
            let name = file.lastPathComponent
            if ["d3d10core.dll", "d3d11.dll", "dxgi.dll", "nvngx.dll"].contains(name) {
                let dest = system32Path.appendingPathComponent(name)
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
                try fileManager.copyItem(at: file, to: dest)
            }
        }
        progressUpdate("复制系统 DLL", 0.6)

        // --- winemetal.dll 和 .so ---
        let winePath = containerDataURL.appendingPathComponent("wine")

        let dllSource = dxmtURL.appendingPathComponent("winemetal.dll")
        let dllDest = winePath.appendingPathComponent("lib/wine/x86_64-windows/winemetal.dll")

        if fileManager.fileExists(atPath: dllSource.path) {
            if fileManager.fileExists(atPath: dllDest.path) {
                try fileManager.removeItem(at: dllDest)
            }
            try fileManager.copyItem(at: dllSource, to: dllDest)
        }

        let soSource = dxmtURL.appendingPathComponent("winemetal.so")
        let soDest = winePath.appendingPathComponent("lib/wine/x86_64-unix/winemetal.so")

        if fileManager.fileExists(atPath: soSource.path) {
            if fileManager.fileExists(atPath: soDest.path) {
                try fileManager.removeItem(at: soDest)
            }
            try fileManager.copyItem(at: soSource, to: soDest)
        }
        progressUpdate("复制 winemetal 文件", 0.65)

        // --- nvngx.dll 到 wine 主路径 ---
        let nvngxSource = dxmtURL.appendingPathComponent("nvngx.dll")
        let nvngxDest = winePath.appendingPathComponent("lib/wine/x86_64-windows/nvngx.dll")

        if fileManager.fileExists(atPath: nvngxSource.path) {
            if fileManager.fileExists(atPath: nvngxDest.path) {
                try fileManager.removeItem(at: nvngxDest)
            }
            try fileManager.copyItem(at: nvngxSource, to: nvngxDest)
        }
        progressUpdate("复制 nvngx.dll 文件", 0.7)

        try flattenDXMTDirectory(at: dxmtURL)
        progressUpdate("扁平化目录", 0.8)

        // 执行 regedit 初始化操作
        let regeditProcess = Process()
        regeditProcess.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        regeditProcess.arguments = ["regedit", "/S"]
        try regeditProcess.run()
        regeditProcess.waitUntilExit()
        progressUpdate("完成", 1.0)

    }
}
