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

        let units = ["B/s", "KiB/s", "MiB/s", "GiB/s"]
        let byteCount = Double(speed)
        var unitIndex = 0

        for i in (0..<units.count).reversed() {
            let threshold = pow(1024.0, Double(i))
            if byteCount >= threshold {
                unitIndex = i
                break
            }
        }

        let value = byteCount / pow(1024.0, Double(unitIndex))
        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 4
        formatter.usesSignificantDigits = true
        formatter.numberStyle = .decimal

        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(numberString) \(units[unitIndex])"
    }
}
