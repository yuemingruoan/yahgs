//
//  WineInstaller.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public struct WineInstaller {
    private let downloadService: DownloadService
    private let initializer: WineInitializer

    public init(downloadService: DownloadService,
                initializer: WineInitializer = WineInitializer()) {
        self.downloadService = downloadService
        self.initializer = initializer
    }

    public func install(progress: @escaping (Double, Int64, Int64, Int64) -> Void) async throws {
        let destinationURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs/wine.tar.xz")

        do {
            try await downloadService.downloadComponent(.wine, to: destinationURL, progress: progress)
        } catch {
            throw error
        }

        try await initializer.initialize(progress: progress)
    }
}
