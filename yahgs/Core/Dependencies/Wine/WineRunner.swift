//
//  WineRunner.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/17.
//

import Foundation
import AppKit

enum RegistryType: String {
    case binary = "REG_BINARY"
    case dword = "REG_DWORD"
    case qword = "REG_QWORD"
    case string = "REG_SZ"
}


class WineRunner {
    
    // Wine 可执行文件路径
    private let wineExecutableURL: URL
    
    // Wine 环境变量（WINEPREFIX 路径）
    private let environment: [String: String]
    
    // hosts 文件及需添加的条目
    private let hostsFilePath = "/etc/hosts"
    private let hostsEntry = "0.0.0.0 dispatchcnglobal.yuanshen.com"
    
    // MARK: - 初始化
    init(winePath: URL, winePrefix: URL) {
        self.wineExecutableURL = winePath.appendingPathComponent("bin/wine")
        self.environment = [
            "WINEPREFIX": winePrefix.path
        ]
    }
    
    // MARK: - 运行 Wine 命令
    func runWineCommand(args: [String], needMSync: Bool = false) throws -> (output: String, exitCode: Int32) {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = wineExecutableURL
        process.arguments = args
        
        var env = environment
        if needMSync {
            env["WINEMSYNC"] = "1"
        }
        process.environment = env
        
        process.currentDirectoryURL = wineExecutableURL.deletingLastPathComponent()
        process.standardOutput = pipe
        process.standardError = pipe
        process.qualityOfService = .userInitiated
        
        try process.run()
        
        guard let outputData = try pipe.fileHandleForReading.readToEnd() else {
            return ("", -1)
        }
        let outputString = String(data: outputData, encoding: .utf8) ?? ""
        process.waitUntilExit()
        
        let status = process.terminationStatus
        
        return (outputString, status)
    }
    
    // MARK: - 修改注册表
    func changeRegistryValue(key: String, name: String, data: String, type: RegistryType) throws {
        _ = try runWineCommand(args: ["reg", "add", key, "-v", name, "-t", type.rawValue, "-d", data, "-f"])
    }
    
    // MARK: - 查询注册表值
    func queryRegistryValue(key: String, name: String, type: RegistryType) throws -> String? {
        let (output, exitCode) = try runWineCommand(args: ["reg", "query", key, "-v", name])
        if exitCode != 0 { return nil }
        
        let lines = output.split(separator: "\n").map { String($0) }
        guard let line = lines.first(where: { $0.contains(type.rawValue) }) else { return nil }
        
        let components = line.split(whereSeparator: { $0.isWhitespace })
        guard let last = components.last else { return nil }
        
        return String(last)
    }
    
    // MARK: - 以管理员权限执行 shell 命令（支持管道输入）
    func executeCommandWithPrivileges(command: String, inputData: Data? = nil) throws {
        var appleScriptCmd = "do shell script \"\(command)\""
        
        if let inputData = inputData {
            guard let inputStr = String(data: inputData, encoding: .utf8) else {
                throw NSError(domain: "Yahgs.WineRunner", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "输入数据无法转换为字符串"
                ])
            }
            let escaped = inputStr.replacingOccurrences(of: "\"", with: "\\\"")
            appleScriptCmd = "do shell script \"echo \\\"\(escaped)\\\" | \(command)\""
        }
        
        appleScriptCmd += " with administrator privileges"
        
        guard let script = NSAppleScript(source: appleScriptCmd) else {
            throw NSError(domain: "Yahgs.WineRunner", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建 AppleScript"])
        }
        
        var errorDict: NSDictionary?
        script.executeAndReturnError(&errorDict)
        
        if let error = errorDict {
            let msg = error[NSAppleScript.errorMessage] as? String ?? "未知错误"
            throw NSError(domain: "Yahgs.WineRunner", code: -2, userInfo: [NSLocalizedDescriptionKey: "AppleScript 执行失败: \(msg)"])
        }
    }
    
    // MARK: - 启动程序并临时修改 hosts 绕过反作弊
    func runProgramWithHostsBypass(programPath: String) throws {
        let entryWithNewline = hostsEntry + "\n"
        try executeCommandWithPrivileges(command: "tee -a \(hostsFilePath)", inputData: entryWithNewline.data(using: .utf8))
        
        let process = Process()
        process.executableURL = wineExecutableURL
        process.arguments = [programPath]
        process.environment = environment
        process.currentDirectoryURL = wineExecutableURL.deletingLastPathComponent()
        process.qualityOfService = .userInitiated
        try process.run()
        
        Thread.sleep(forTimeInterval: 5.0)
        
        let sedCmd = "sed -i '' '/^0\\.0\\.0\\.0 dispatchcnglobal\\.yuanshen\\.com$/d' \(hostsFilePath)"
        try executeCommandWithPrivileges(command: sedCmd)
    }
    
    // MARK: - 初始化 Wine 环境
    /// 初始化 WinePrefix 并设置 Windows 版本为 Windows 10
    func initializeWineEnvironment() throws {
        // 1. 确保 WINEPREFIX 目录存在
        let winePrefixPath = environment["WINEPREFIX"] ?? ""
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: winePrefixPath) {
            try fileManager.createDirectory(atPath: winePrefixPath, withIntermediateDirectories: true)
        }

        // 2. 执行 winecfg --no-ui 进行初始化
        let (output, status) = try runWineCommand(args: ["winecfg", "--no-ui"])
        if status != 0 {
            throw NSError(domain: "WineRunner", code: Int(status), userInfo: [
                NSLocalizedDescriptionKey: "winecfg 初始化失败，输出：\(output)"
            ])
        }

        // 3. 设置 Windows 版本信息
        try changeRegistryValue(
            key: "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion",
            name: "CurrentVersion",
            data: "10.0",
            type: .string
        )
        try changeRegistryValue(
            key: "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion",
            name: "CurrentBuildNumber",
            data: "19041",
            type: .string
        )
        try changeRegistryValue(
            key: "HKCU\\Software\\Microsoft\\Windows NT\\CurrentVersion",
            name: "ProductName",
            data: "Windows 10",
            type: .string
        )

        // 4. 启用 Retina 模式（Mac Driver 下）
        try changeRegistryValue(
            key: "HKCU\\Software\\Wine\\Mac Driver",
            name: "RetinaMode",
            data: "Y",
            type: .string
        )

        // 5. 设置 DPI 为 192（LogPixels，DWORD 类型）
        try changeRegistryValue(
            key: "HKCU\\Control Panel\\Desktop",
            name: "LogPixels",
            data: "192",
            type: .dword
        )

        // 6. 映射左侧 Command 键为 Control 键
        try changeRegistryValue(
            key: "HKCU\\Software\\Wine\\Mac Driver",
            name: "CommandIsCtrl",
            data: "Y",
            type: .string
        )

        // 7. 日志
        print("Wine 环境初始化成功，WINEPREFIX: \(winePrefixPath)，DPI 设置为192，启用 Retina 模式，Command 键映射为 Control")
    }
}

extension WineRunner {
    // MARK: - 安装 Wine 并写入游戏 WinePrefix 路径
    func InstallWine(progressUpdate: ((Double) -> Void)? = nil) throws {
        // 空实现
    }
}
