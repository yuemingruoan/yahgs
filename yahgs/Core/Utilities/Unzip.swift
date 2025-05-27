//
//  Unzip.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import Foundation

public struct Unzip {
    public static func extract(from source: URL, to destination: URL) async throws {
        let fileExtension = source.pathExtension.lowercased()
        var args: [String]

        switch fileExtension {
        case "xz":
            args = ["-xJmf", source.path, "--unlink", "-C", destination.path]
        case "gz":
            args = ["-xzmf", source.path, "--unlink", "-C", destination.path]
        case "bz2":
            args = ["-xjmf", source.path, "--unlink", "-C", destination.path]
        default:
            throw NSError(domain: "Unzip", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unsupported archive format"])
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = args

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw NSError(domain: "Unzip", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to extract archive"])
        }

        // 删除压缩包
        try? FileManager.default.removeItem(at: source)
        print("Deleted source archive: \(source.path)")
    }
}
