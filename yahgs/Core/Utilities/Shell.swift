//
//  Shell.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/20.
//

import Foundation

public enum Shell {
    @discardableResult
    public static func run(_ launchPath: String, arguments: [String] = []) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [launchPath] + arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        print("Running shell command: \(launchPath) \(arguments.joined(separator: " "))")

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)

        print("Command output:\n\(output)")
        return output
    }
}
