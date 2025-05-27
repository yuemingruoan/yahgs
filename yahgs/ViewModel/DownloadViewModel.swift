//
//  DownloadViewModel.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//

import Foundation
import Combine

@MainActor
public class DownloadViewModel: ObservableObject {
    // 绑定给UI显示的进度百分比，范围0.0 ~ 1.0
    @Published public private(set) var progress: Double = 0.0 {
        didSet {
            print("[DownloadViewModel] progress didSet: \(progress)")
        }
    }

    // 格式化后的已下载大小文本，如 "32.5 MB"
    @Published public private(set) var downloadedSize: String = "0 MB" {
        didSet {
            print("[DownloadViewModel] downloadedSize didSet: \(downloadedSize)")
        }
    }

    // 格式化后的总大小文本，如 "120 MB"
    @Published public private(set) var totalSize: String = "0 MB" {
        didSet {
            print("[DownloadViewModel] totalSize didSet: \(totalSize)")
        }
    }

    // 格式化后的当前下载速度，如 "3.2 MB/s"
    @Published public private(set) var speed: String = "0 MB/s" {
        didSet {
            print("[DownloadViewModel] speed didSet: \(speed)")
        }
    }

    // 当前下载状态，方便UI显示不同状态
    @Published public private(set) var downloadState: DownloadState = .idle

    // 错误信息，供UI展示
    @Published public private(set) var errorMessage: String? = nil

    // 私有下载服务实例
    private let downloadService: DownloadService

    // 当前下载组件
    private var currentComponent: DownloadComponent?

    // 当前下载目标路径
    private var currentDestination: URL?

    // 格式化字节数为 MB 字符串
    public func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }

    public func formatSpeed(_ bytesPerSecond: Int64) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var speed = Double(bytesPerSecond)
        var unitIndex = 0

        while speed >= 1024.0 && unitIndex < units.count - 1 {
            speed /= 1024.0
            unitIndex += 1
        }

        let formatter = NumberFormatter()
        formatter.maximumSignificantDigits = 4
        formatter.usesSignificantDigits = true
        formatter.numberStyle = .decimal

        let numberString = formatter.string(from: NSNumber(value: speed)) ?? "\(speed)"
        return "\(numberString) \(units[unitIndex])"
    }

    public init() {
        self.downloadService = DownloadService()
    }

    public init(downloadService: DownloadService) {
        self.downloadService = downloadService
    }

    // MARK: - 下载控制接口

    /// 开始下载指定组件，指定存储路径
    public func startDownload(component: DownloadComponent, to destination: URL) async throws {
        print("[DownloadViewModel] startDownload called for component: \(component.rawValue)")
        guard downloadState != .downloading else {
            print("[DownloadViewModel] downloadState is already downloading, ignoring new start request")
            return
        }

        currentComponent = component
        currentDestination = destination
        downloadState = .waiting
        errorMessage = nil
        progress = 0
        downloadedSize = "0 MB"
        totalSize = "0 MB"
        speed = "0 MB/s"

        downloadState = .downloading
        try await downloadService.downloadComponent(component, to: destination, progress: { [weak self] percent, downloaded, total, speedBytes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("[DownloadViewModel] progress update: \(percent), downloaded: \(downloaded), total: \(total), speed: \(speedBytes)")
                self.progress = percent
                self.downloadedSize = self.formatByteCount(downloaded)
                self.totalSize = self.formatByteCount(total)
                self.speed = self.formatSpeed(speedBytes)
            }
        })

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("[DownloadViewModel] download completed")
            self.progress = 1.0
            self.downloadState = .completed
            self.speed = "0 MB/s"
        }
    }

    /// 暂停当前下载
    public func pause() {
        print("[DownloadViewModel] pause called")
        guard let component = currentComponent, downloadState == .downloading else {
            print("[DownloadViewModel] pause ignored, no active download")
            return
        }
        downloadService.pause(component)
        downloadState = .paused
    }

    /// 恢复当前下载
    public func resume() {
        print("[DownloadViewModel] resume called")
        guard let component = currentComponent, downloadState == .paused else {
            print("[DownloadViewModel] resume ignored, not paused")
            return
        }
        downloadService.resume(component)
        downloadState = .downloading
    }

    /// 取消当前下载
    public func cancel() {
        print("[DownloadViewModel] cancel called")
        guard let component = currentComponent else {
            print("[DownloadViewModel] cancel ignored, no active download")
            return
        }
        downloadService.cancel(component)
        resetState()
    }

    /// 重置状态为初始
    private func resetState() {
        print("[DownloadViewModel] resetState called")
        progress = 0
        downloadedSize = "0 MB"
        totalSize = "0 MB"
        speed = "0 MB/s"
        downloadState = .idle
        errorMessage = nil
        currentComponent = nil
        currentDestination = nil
    }
    @MainActor
    public func reset() async {
        resetState()
    }
}
