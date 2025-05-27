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
                initializer: DxmtInitializer = DxmtInitializer()) {
        self.downloadService = downloadService
        self.initializer = initializer
    }

    public func installDxmt(from archivePath: URL, progress: @escaping (Double) -> Void) async throws {
        try await initializer.initialize(from: archivePath) {  percent in
            progress(percent)
        }
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
