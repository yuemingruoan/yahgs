//
//  WineInitialize.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation
import Zip

public struct WineInitializer {
    public init() {}

    public func initialize(progressUpdate: @escaping (String, Double) -> Void) async throws {
        let fileManager = FileManager.default
        let containerDataURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")
        let wineURL = containerDataURL.appendingPathComponent("wine")
        let winePrefix = containerDataURL.appendingPathComponent("wineprefix")

        // 检查 wine 目录是否存在且非空，存在则跳过初始化
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: wineURL.path, isDirectory: &isDir), isDir.boolValue {
            let contents = try fileManager.contentsOfDirectory(atPath: wineURL.path)
            if !contents.isEmpty {
                progressUpdate("已存在 Wine 目录，跳过初始化", 1.0)
                return
            }
        }
        progressUpdate("开始初始化 Wine", 0.0)

        // 临时解压目录指向实际的 .app bundle 目录
        let tempExtractPath = containerDataURL.appendingPathComponent("Wine Devel.app")

        // 如果存在旧 wine 目录，先删除
        if fileManager.fileExists(atPath: wineURL.path) {
            try fileManager.removeItem(at: wineURL)
            progressUpdate("删除旧 Wine 目录", 0.2)
        } else {
            progressUpdate("准备移动 Wine 文件", 0.2)
        }

        // 移动解压出来的 wine 目录到目标位置
        let extractedWinePath = tempExtractPath.appendingPathComponent("Contents/Resources/wine")
        try fileManager.moveItem(at: extractedWinePath, to: wineURL)
        progressUpdate("移动 Wine 文件", 0.4)

        // 自动删除解压的 .app 目录
        let appBundlePath = containerDataURL.appendingPathComponent("Wine Devel.app")
        if fileManager.fileExists(atPath: appBundlePath.path) {
            try fileManager.removeItem(at: appBundlePath)
        }
        progressUpdate("删除临时文件", 0.5)

        // 创建 wineprefix 目录
        if !fileManager.fileExists(atPath: winePrefix.path) {
            try fileManager.createDirectory(at: winePrefix, withIntermediateDirectories: true)
        }
        progressUpdate("创建 WinePrefix 目录", 0.6)

        // 创建 WineRunner 实例，初始化环境
        let wineRunner = WineRunner(winePath: wineURL.appendingPathComponent("bin/wine"), winePrefix: winePrefix)
        try wineRunner.initializeWineEnvironment()
        progressUpdate("初始化 Wine 环境", 0.75)

        // 运行 winecfg 命令，确保环境正确
        let (output, status) = try wineRunner.runWineCommand(args: ["winecfg"])
        if status != 0 {
            throw NSError(domain: "WineInitializeError", code: Int(status), userInfo: [NSLocalizedDescriptionKey: output])
        }
        progressUpdate("运行 winecfg", 0.85)

        // 创建安装完成标记文件
        let flagURL = containerDataURL.appendingPathComponent(".installed.flag")
        fileManager.createFile(atPath: flagURL.path, contents: nil, attributes: nil)
        progressUpdate("完成初始化", 1.0)
    }
}
