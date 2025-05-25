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

// MARK: - DownloadService

public final class DownloadService {
    private let downloadManager: DownloadManager

    init(downloadManager: DownloadManager = DownloadManager.shared) {
        self.downloadManager = downloadManager
    }

    // 下载组件
    func downloadComponent(_ component: DownloadComponent, to destination: URL, progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws {
        let url = self.url(for: component)
        try await downloadManager.downloadFile(from: url, to: destination, progress: progress)
    }

    func install(_ component: DownloadComponent, to destination: URL, progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws -> URL {
        try await downloadComponent(component, to: destination, progress: progress)
        return destination
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
