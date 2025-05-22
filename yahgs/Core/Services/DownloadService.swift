//
//  DownloadService.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/17.
//

import Foundation

// MARK: - Download URLs

enum DownloadURLs {
    static let wine = URL(string: "https://github.com/Gcenx/macOS_Wine_builds/releases/download/10.8/wine-devel-10.8-osx64.tar.xz")!
    static let dxmt = URL(string: "https://github.com/3Shain/dxmt/releases/download/v0.51/dxmt-v0.51-builtin.tar.gz")!
}

// MARK: - Component Enum

enum DownloadComponent: String, CaseIterable, Hashable, Equatable {
    case wine = "Wine"
    case dxmt = "DXMT"
}

// MARK: - DownloadService

public final class DownloadService {
    private let downloadManager: DownloadManager

    init(downloadManager: DownloadManager = DownloadManager()) {
        self.downloadManager = downloadManager
    }

    // 下载并解压
    func downloadComponent(_ component: DownloadComponent, to destination: URL, progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws {
        do {
            progress(0.0, 0, 1, 0)
            let url = self.url(for: component)
            try await downloadManager.downloadFile(from: url, to: destination, progress: progress)
            
            let extractPath = destination.deletingLastPathComponent()

            try await unzip(at: destination, to: extractPath)

            do {
                try FileManager.default.removeItem(at: destination)
            } catch {
            }
        } catch {
            throw error
        }
    }
    
    func unzip(at source: URL, to destination: URL) async throws {
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
            throw NSError(domain: "UnzipError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file extension: \(fileExtension)"])
        }
        process.arguments = args
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw NSError(domain: "UnzipError", code: Int(process.terminationStatus), userInfo: nil)
        }
    }

    func install(_ component: DownloadComponent, progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws {
        switch component {
        case .wine:
            let containerDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Yahgs")
            let zipURL = containerDir.appendingPathComponent("wine.tar.xz")
            try await downloadComponent(.wine, to: zipURL, progress: progress)

            let initializer = WineInitializer()
            try await initializer.initialize(progress: progress)

        case .dxmt:
            let containerDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Yahgs")
            let tarGzURL = containerDir.appendingPathComponent("dxmt.tar.gz")
            try await downloadComponent(.dxmt, to: tarGzURL, progress: progress)

            let repository = DefaultSettingsRepository()
            let initializer = DxmtInitializer(repository: repository)
            try initializer.initialize(from: containerDir)
        }
    }

    func cancel(_ component: DownloadComponent) {
        downloadManager.cancel(url: url(for: component))
    }

    func pause(_ component: DownloadComponent) {
        downloadManager.pause(url: url(for: component))
    }

    func resume(_ component: DownloadComponent) {
        downloadManager.resume(url: url(for: component))
    }

    private func url(for component: DownloadComponent) -> URL {
        switch component {
        case .wine:
            return DownloadURLs.wine
        case .dxmt:
            return DownloadURLs.dxmt
        }
    }
}
