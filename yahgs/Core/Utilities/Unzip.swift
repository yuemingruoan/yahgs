//
//  Unzip.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import Foundation

public enum UnzipError: Error {
    case unsupportedFormat(String)
    case failed(Int32)
}

public struct Unzip {
    public static let supportedExtensions = ["gz", "bz2", "xz", "zip"]

    public static func extract(from source: URL, to destination: URL) async throws {
        print("Unzipping \(source.lastPathComponent) to \(destination.path)...")

        let process = Process()
        let fileExtension = source.pathExtension.lowercased()
        var args: [String]

        switch fileExtension {
        case "gz":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            args = ["-xzf", source.path, "-C", destination.path]
        case "bz2":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            args = ["-xjf", source.path, "-C", destination.path]
        case "xz":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
            args = ["-xJf", source.path, "-C", destination.path]
        case "zip":
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            args = [source.path, "-d", destination.path]
        default:
            throw UnzipError.unsupportedFormat(fileExtension)
        }

        process.arguments = args
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw UnzipError.failed(process.terminationStatus)
        }
    }
}
