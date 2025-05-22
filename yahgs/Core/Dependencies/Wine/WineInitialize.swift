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

    public func initialize(progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws {
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
                return
            }
        }

        // 临时解压目录指向实际的 .app bundle 目录
        let tempExtractPath = containerDataURL.appendingPathComponent("Wine Devel.app")

        // 如果存在旧 wine 目录，先删除
        let extractedWinePath = tempExtractPath.appendingPathComponent("Contents/Resources/wine")
        if fileManager.fileExists(atPath: wineURL.path) {
            try fileManager.removeItem(at: wineURL)
        }
        // 移动解压出来的 wine 目录到目标位置
        try fileManager.moveItem(at: extractedWinePath, to: wineURL)

        // 自动删除解压的 .app 目录
        let appBundlePath = containerDataURL.appendingPathComponent("Wine Devel.app")
        if fileManager.fileExists(atPath: appBundlePath.path) {
            try fileManager.removeItem(at: appBundlePath)
        }

        // 创建 wineprefix 目录
        if !fileManager.fileExists(atPath: winePrefix.path) {
            try fileManager.createDirectory(at: winePrefix, withIntermediateDirectories: true)
        }

        // 执行 winecfg 初始化
        let wineBin = wineURL.appendingPathComponent("bin/wine")
        let process = Process()
        process.executableURL = wineBin
        process.arguments = ["winecfg"]
        process.environment = ["WINEPREFIX": winePrefix.path]

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "WineInitializeError", code: Int(process.terminationStatus), userInfo: nil)
        }

        // 创建安装完成标记文件
        let flagURL = containerDataURL.appendingPathComponent(".installed.flag")
        fileManager.createFile(atPath: flagURL.path, contents: nil, attributes: nil)
    }
}
