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

    // 格式化后的已下载大小文本，如 "32.5 MiB"
    @Published public private(set) var downloadedSize: String = "0 MiB" {
        didSet {
            print("[DownloadViewModel] downloadedSize didSet: \(downloadedSize)")
        }
    }

    // 格式化后的总大小文本，如 "120 MiB"
    @Published public private(set) var totalSize: String = "0 MiB" {
        didSet {
            print("[DownloadViewModel] totalSize didSet: \(totalSize)")
        }
    }

    // 格式化后的当前下载速度，如 "3.2 MiB/s"
    @Published public private(set) var speed: String = "0 MiB/s" {
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

    // 格式化字节数为自适应单位字符串
    public func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = .useAll
        formatter.countStyle = .binary
        formatter.includesUnit = true
        formatter.includesActualByteCount = false
        return formatter.string(fromByteCount: bytes)
    }

    public func formatSpeed(_ bytesPerSecond: Int64) -> String {
        let units = ["B/s", "KiB/s", "MiB/s", "GiB/s"]
        let byteCount = Double(bytesPerSecond)
        var unitIndex = 0

        for i in (0..<units.count).reversed() {
            let threshold = pow(1024.0, Double(i))
            let value = byteCount / threshold
            if value >= 10.0 {
                unitIndex = i
                break
            }
        }

        let speed = byteCount / pow(1024.0, Double(unitIndex))
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
        downloadedSize = "0 MiB"
        totalSize = "0 MiB"
        speed = "0 MiB/s"

        downloadState = .downloading
        try await downloadService.downloadComponent(component, to: destination, progress: { [weak self] percent, downloaded, total, speedBytes in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("[DownloadViewModel] progress update: \(percent), downloaded: \(downloaded), total: \(total), speed: \(speedBytes)")
                self.progress = percent
                self.downloadedSize = self.formatBytes(downloaded)
                self.totalSize = self.formatBytes(total)
                self.speed = self.formatSpeed(speedBytes)
            }
        })

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("[DownloadViewModel] download completed")
            self.progress = 1.0
            self.downloadState = .completed
            self.speed = "0 MiB/s"
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
        downloadedSize = "0 MiB"
        totalSize = "0 MiB"
        speed = "0 MiB/s"
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

private extension DownloadViewModel {
    /// 格式化字节数为带二进制单位（B, KiB, MiB, GiB）的字符串
    func formatBytes(_ bytes: Int64) -> String {
        let units = ["B", "KiB", "MiB", "GiB"]
        let byteCount = Double(bytes)
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
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal

        let numberString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(numberString) \(units[unitIndex])"
    }
}
