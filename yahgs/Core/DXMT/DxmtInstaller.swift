//
//  DxmtInstaller.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//


import Foundation
import Zip

public struct DxmtInstaller {
    public init() {}

    public func install() async throws {
        let fileManager = FileManager.default

        // 容器 Data 路径
        let containerDataURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/Yahgs/Data")

        // 目标解压目录 dxmt
        let dxmtURL = containerDataURL.appendingPathComponent("dxmt")
        try? fileManager.createDirectory(at: dxmtURL, withIntermediateDirectories: true)

        // 下载目标路径
        let fileName = "dxmt.zip"
        let zipURL = dxmtURL.appendingPathComponent(fileName)

        // GitHub Release 地址
        let downloadURL = URL(string: "https://github.com/3Shain/dxmt/releases/latest/download/dxmt.zip")!

        // 下载文件
        let (tempURL, _) = try await URLSession.shared.download(from: downloadURL)
        try? fileManager.removeItem(at: zipURL)
        try fileManager.moveItem(at: tempURL, to: zipURL)

        // 解压缩
        try Zip.unzipFile(zipURL, destination: dxmtURL, overwrite: true, password: nil)
    }
}
