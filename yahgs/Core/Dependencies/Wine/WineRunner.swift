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
        self.wineExecutableURL = winePath
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
    /// 使用 shell 脚本初始化 Wine 环境
    func initializeWineEnvironment() throws {
        guard let winePrefix = environment["WINEPREFIX"] else {
            throw NSError(domain: "WineRunner", code: -1, userInfo: [NSLocalizedDescriptionKey: "WINEPREFIX 未设置"])
        }
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: winePrefix) {
            try fileManager.createDirectory(atPath: winePrefix, withIntermediateDirectories: true)
        }

        let wineLibPath = wineExecutableURL.deletingLastPathComponent().appendingPathComponent("../lib").path

        let quotedPrefix = "\"\(winePrefix)\""
        let quotedLibPath = "\"\(wineLibPath)\""
        let winebootPath = wineExecutableURL.deletingLastPathComponent().appendingPathComponent("wineboot").path
        let quotedWineboot = "\"\(winebootPath)\""
        let quotedWine = "\"\(wineExecutableURL.path)\""

        print("winebootPath: \(winebootPath)")
        print("wineExecutable: \(wineExecutableURL.path)")

        let envPrefix = "export WINEPREFIX=\(quotedPrefix); export DYLD_FALLBACK_LIBRARY_PATH=\(quotedLibPath);"

        print("开始执行 wineboot -u 初始化命令")
        try Shell.run("/bin/bash", arguments: ["-c", "\(envPrefix) \(quotedWineboot) -u"])
        print("wineboot -u 初始化命令执行完成")

        print("开始执行 reg add 注册表命令")

        // 新增环境变量用于禁用 GUI 弹窗
        var env = environment
        env["WINEDEBUG"] = "-all"
        env["WINEDLLOVERRIDES"] = "mshtml,mscoree="

        try Shell.run("/bin/bash", arguments: ["-c", "\(envPrefix) \(quotedWine) reg add \"HKCU\\\\Software\\\\Wine\\\\Wine\\\\Config\" /v Version /d win10 /f"])

        print("reg add 注册表命令执行完成")

        print("Wine 环境初始化成功，WINEPREFIX: \(winePrefix)，使用 shell 脚本初始化")
    }
}
