//
//  DxmtInitialize.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public struct DxmtInitializer {
    private let repository: SettingsRepository

    public init(repository: SettingsRepository) {
        self.repository = repository
    }

    // 保存安装版本
    private func saveInstalledVersion(_ version: String) {
        var settings = repository.load()
        settings.dxmtVersion = version
        repository.save(settings)
        print("DXMT version saved: \(version)")
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

    // 初始化过程（同步）
    public func initialize(from dxmtURL: URL) throws {
        let fileManager = FileManager.default
        let containerDataURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")

        // --- 将 dxmt 内容同步复制到 gameprefix ---
        let gamePrefixPath = containerDataURL.appendingPathComponent("gameprefix")
        let system32Path = gamePrefixPath.appendingPathComponent("drive_c/windows/system32")
        try fileManager.createDirectory(at: system32Path, withIntermediateDirectories: true)

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

        // --- nvngx.dll 到 wine 主路径 ---
        let nvngxSource = dxmtURL.appendingPathComponent("nvngx.dll")
        let nvngxDest = winePath.appendingPathComponent("lib/wine/x86_64-windows/nvngx.dll")

        if fileManager.fileExists(atPath: nvngxSource.path) {
            if fileManager.fileExists(atPath: nvngxDest.path) {
                try fileManager.removeItem(at: nvngxDest)
            }
            try fileManager.copyItem(at: nvngxSource, to: nvngxDest)
        }

        try flattenDXMTDirectory(at: dxmtURL)

        // 可选：调用保存版本方法
        // saveInstalledVersion("版本号") // 具体版本号由调用方传入
    }
}
