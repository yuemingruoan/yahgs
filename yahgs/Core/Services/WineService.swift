//
//  WineService.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public class WineService {
    private let downloadService: DownloadService
    private let initializer: WineInitializer

    public init(downloadService: DownloadService,
                initializer: WineInitializer = WineInitializer()) {
        self.downloadService = downloadService
        self.initializer = initializer
    }

    public func installWine(progress: @escaping (String, Double) -> Void) async throws {
        let destinationURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs/wine.tar.xz")

        try await downloadService.downloadComponent(.wine, to: destinationURL) { percent, downloaded, total, speed in
            let formattedDownloaded = ByteCountFormatter.string(fromByteCount: downloaded, countStyle: .file)
            let formattedTotal = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
            let formattedSpeed = self.formatSpeed(speed)
            let formatted = "\(formattedDownloaded) / \(formattedTotal) • \(formattedSpeed)"
            progress(formatted, percent)
        }
        try await initializer.initialize(progressUpdate: progress)
    }
    
    private func formatSpeed(_ speed: Int64) -> String {
        if speed == 0 { return "0 B/s" }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true

        let speedString = formatter.string(fromByteCount: speed)
        return "\(speedString)/s"
    }
}
