//
//  DxmtInitialize.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public struct DxmtInitializer {
    public init() {}

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
    public func initialize(from archivePath: URL, progressUpdate: @escaping (Double) -> Void) async throws {
        let fileManager = FileManager.default
        let containerDataURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")

        let dxmtURL = containerDataURL.appendingPathComponent("dxmt")

        // 检查 dxmt 目录是否存在且非空，若是则跳过初始化
        if fileManager.fileExists(atPath: dxmtURL.path) {
            let contents = try fileManager.contentsOfDirectory(at: dxmtURL, includingPropertiesForKeys: nil)
            if !contents.isEmpty {
                print("[DxmtInitializer] dxmt already initialized, skipping")
                progressUpdate(1.0)
                return
            }
        }
        print("[DxmtInitializer] starting dxmt initialization")
        progressUpdate(0.0)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 解压 Dxmt 安装包
        print("[DxmtInitializer] extracting dxmt archive")
        progressUpdate(0.1)
        try await Task.sleep(nanoseconds: 500_000_000)
        try await Unzip.extract(from: archivePath, to: containerDataURL)

        // 修改解压路径为 v0.51 文件夹路径
        let tempExtractPath = containerDataURL.appendingPathComponent("v0.51")

        // 如果存在旧的 dxmt 目录，先删除
        if fileManager.fileExists(atPath: dxmtURL.path) {
            print("[DxmtInitializer] removing old dxmt directory")
            try fileManager.removeItem(at: dxmtURL)
        }
        progressUpdate(0.1)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 合并：将解压目录整体移动到 dxmt 目录，并扁平化 dxmt 目录
        let dxmtSourceURL = tempExtractPath
        if fileManager.fileExists(atPath: dxmtSourceURL.path) {
            try flattenDXMTDirectory(at: dxmtSourceURL)
            try fileManager.createDirectory(at: dxmtURL, withIntermediateDirectories: true)
            let flattenedContents = try fileManager.contentsOfDirectory(at: dxmtSourceURL, includingPropertiesForKeys: nil)
            for file in flattenedContents {
                let dest = dxmtURL.appendingPathComponent(file.lastPathComponent)
                if fileManager.fileExists(atPath: dest.path) {
                    try fileManager.removeItem(at: dest)
                }
                try fileManager.moveItem(at: file, to: dest)
            }
            try fileManager.removeItem(at: dxmtSourceURL)
        }
        progressUpdate(0.3)
        try await Task.sleep(nanoseconds: 500_000_000)
        print("[DxmtInitializer] flattened and moved dxmt resources")

        // 删除临时解压目录（已移动，通常不存在）
        if fileManager.fileExists(atPath: tempExtractPath.path) {
            print("[DxmtInitializer] removing temporary extraction directory")
            try fileManager.removeItem(at: tempExtractPath)
        }
        progressUpdate(0.4)
        try await Task.sleep(nanoseconds: 500_000_000)

        // --- 将 dxmt 内容同步复制到 wineprefix ---
        let winePrefix = containerDataURL.appendingPathComponent("wineprefix")
        let system32Path = winePrefix.appendingPathComponent("drive_c/windows/system32")
        try fileManager.createDirectory(at: system32Path, withIntermediateDirectories: true)
        print("[DxmtInitializer] creating wine prefix directories")
        progressUpdate(0.5)
        try await Task.sleep(nanoseconds: 500_000_000)

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
        print("[DxmtInitializer] copied system DLLs")
        progressUpdate(0.7)
        try await Task.sleep(nanoseconds: 500_000_000)

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
        print("[DxmtInitializer] copied winemetal files")
        progressUpdate(0.8)
        try await Task.sleep(nanoseconds: 500_000_000)

        // --- nvngx.dll 到 wine 主路径 ---
        let nvngxSource = dxmtURL.appendingPathComponent("nvngx.dll")
        let nvngxDest = winePath.appendingPathComponent("lib/wine/x86_64-windows/nvngx.dll")

        if fileManager.fileExists(atPath: nvngxSource.path) {
            if fileManager.fileExists(atPath: nvngxDest.path) {
                try fileManager.removeItem(at: nvngxDest)
            }
            try fileManager.copyItem(at: nvngxSource, to: nvngxDest)
        }
        print("[DxmtInitializer] copied nvngx.dll file")
        progressUpdate(0.9)
        try await Task.sleep(nanoseconds: 500_000_000)

        // 初始化完成
        print("[DxmtInitializer] initialization complete")
        progressUpdate(1.0)

    }
}
