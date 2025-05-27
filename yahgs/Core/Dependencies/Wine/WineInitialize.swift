//
//  WineInitialize.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public struct WineInitializer {
    public init() {}

    public func initialize(from archivePath: URL, progressUpdate: @escaping (Double) -> Void) async throws {
        let fileManager = FileManager.default
        let containerDataURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")
        let wineURL = containerDataURL.appendingPathComponent("wine")
        let winePrefix = containerDataURL.appendingPathComponent("wineprefix")

        // 检查 wine 和 wineprefix 目录是否都存在且非空，存在则跳过初始化
        var isDir: ObjCBool = false
        let wineExists = fileManager.fileExists(atPath: wineURL.path, isDirectory: &isDir) && isDir.boolValue
        let winePrefixExists = fileManager.fileExists(atPath: winePrefix.path, isDirectory: &isDir) && isDir.boolValue

        if wineExists && winePrefixExists {
            let wineContents = try fileManager.contentsOfDirectory(atPath: wineURL.path)
            let winePrefixContents = try fileManager.contentsOfDirectory(atPath: winePrefix.path)

            if !wineContents.isEmpty && !winePrefixContents.isEmpty {
                print("[WineInitializer] 已存在 Wine 和 WinePrefix 目录，跳过初始化")
                progressUpdate(1.0)
                return
            }
        }
        print("[WineInitializer] 开始初始化 Wine")
        progressUpdate(0.0)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 解压 wine.tar.xz
        print("[WineInitializer] 解压 Wine 安装包")
        progressUpdate(0.10)
        try await Task.sleep(nanoseconds: 500_000_000)
        try await Unzip.extract(from: archivePath, to: containerDataURL)

        // 临时解压目录指向实际的 .app bundle 目录
        let tempExtractPath = containerDataURL.appendingPathComponent("Wine Devel.app")

        // 如果存在旧 wine 目录，先删除
        if fileManager.fileExists(atPath: wineURL.path) {
            print("[WineInitializer] 删除旧 Wine 目录")
            progressUpdate(0.3)
            try await Task.sleep(nanoseconds: 500_000_000)
            try fileManager.removeItem(at: wineURL)
        } else {
            print("[WineInitializer] 准备移动 Wine 文件")
            progressUpdate(0.3)
            try await Task.sleep(nanoseconds: 500_000_000)
        }

        // 移动解压出来的 wine 目录到目标位置
        let extractedWinePath = tempExtractPath.appendingPathComponent("Contents/Resources/wine")
        try fileManager.moveItem(at: extractedWinePath, to: wineURL)
        print("[WineInitializer] 移动 Wine 文件")
        progressUpdate(0.5)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 自动删除解压的 .app 目录
        let appBundlePath = containerDataURL.appendingPathComponent("Wine Devel.app")
        if fileManager.fileExists(atPath: appBundlePath.path) {
            try fileManager.removeItem(at: appBundlePath)
        }
        print("[WineInitializer] 删除临时文件")
        progressUpdate(0.6)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 创建 wineprefix 目录
        if !fileManager.fileExists(atPath: winePrefix.path) {
            try fileManager.createDirectory(at: winePrefix, withIntermediateDirectories: true)
        }
        print("[WineInitializer] 创建 WinePrefix 目录")
        progressUpdate(0.7)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 创建 WineRunner 实例，初始化环境
        let wineRunner = WineRunner(winePath: wineURL.appendingPathComponent("bin/wine"), winePrefix: winePrefix)
        try wineRunner.initializeWineEnvironment()
        print("[WineInitializer] 初始化 Wine 环境")
        progressUpdate(0.9)
        try await Task.sleep(nanoseconds: 500_000_000)

        print("[WineInitializer] 完成初始化")
        progressUpdate(1.0)
    }
}
