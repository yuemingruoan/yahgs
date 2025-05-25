//
//  DxmtService.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public class DxmtService {
    private let downloadService: DownloadService
    private let initializer: DxmtInitializer

    public init(downloadService: DownloadService,
                repository: SettingsRepository,
                initializer: DxmtInitializer? = nil) {
        self.downloadService = downloadService
        if let initializer = initializer {
            self.initializer = initializer
        } else {
            self.initializer = DxmtInitializer(repository: repository)
        }
    }

    public func installDxmt(progress: @escaping (String, Double) -> Void) async throws {
        let destinationURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs/dxmt.tar.xz")

        try await downloadService.downloadComponent(.dxmt, to: destinationURL) { percent, downloaded, total, speed in
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
