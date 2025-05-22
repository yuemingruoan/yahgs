//
//  DownloadManager.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    
    private var session: URLSession!
    private var tasks: [URL: URLSessionDownloadTask] = [:]
    private var progressHandlers: [URL: (Double, Int64, Int64, Int64) -> Void] = [:]
    private var completionHandlers: [URL: (Result<URL, Error>) -> Void] = [:]
    
    private var lastDownloadInfo: [URL: (bytesWritten: Int64, time: Date)] = [:]
    private var resumeDataMap: [URL: Data] = [:]
    private var lastProgressUpdateTime: [URL: Date] = [:]
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func download(from url: URL, to destination: URL,
                  progress: @escaping (Double, Int64, Int64, Int64) -> Void,
                  completion: @escaping (Result<URL, Error>) -> Void) {
        let task: URLSessionDownloadTask
        if let resumeData = resumeDataMap[url] {
            task = session.downloadTask(withResumeData: resumeData)
            resumeDataMap.removeValue(forKey: url)
        } else {
            task = session.downloadTask(with: url)
        }
        task.taskDescription = destination.path
        tasks[url] = task
        progressHandlers[url] = progress
        completionHandlers[url] = completion
        task.resume()
    }
    
    func pause(url: URL) {
        tasks[url]?.suspend()
        print("[DownloadManager] 暂停下载：\(url.lastPathComponent)")
    }
    
    func resume(url: URL) {
        tasks[url]?.resume()
        print("[DownloadManager] 继续下载：\(url.lastPathComponent)")
    }
    
    func cancel(url: URL) {
        tasks[url]?.cancel { data in
            if let data = data {
                self.resumeDataMap[url] = data
            }
            self.cleanup(url: url)
        }
        print("[DownloadManager] 取消下载：\(url.lastPathComponent)")
    }
    
    private func cleanup(url: URL) {
        tasks.removeValue(forKey: url)
        progressHandlers.removeValue(forKey: url)
        completionHandlers.removeValue(forKey: url)
        lastDownloadInfo.removeValue(forKey: url)
        resumeDataMap.removeValue(forKey: url)
        lastProgressUpdateTime.removeValue(forKey: url)
    }
    
    // MARK: - Delegate Methods
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        // 复制文件逻辑
        
        let now = Date()
        let lastInfo = lastDownloadInfo[url] ?? (0, now)
        let elapsed = now.timeIntervalSince(lastInfo.time)
        
        // 节流逻辑：0.3秒内不重复回调进度
        if let lastUpdate = lastProgressUpdateTime[url], now.timeIntervalSince(lastUpdate) < 0.3 {
            return
        }
        lastProgressUpdateTime[url] = now
        
        let deltaBytes = totalBytesWritten - lastInfo.bytesWritten
        let speed = elapsed > 0 ? Int64(Double(deltaBytes) / elapsed) : 0
        
        lastDownloadInfo[url] = (totalBytesWritten, now)
        
        let percent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandlers[url]?(percent, totalBytesWritten, totalBytesExpectedToWrite, speed)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url,
              let destinationPath = downloadTask.taskDescription else { return }

        // 补发最后一次进度更新，防止节流漏掉100%
        let totalBytes = downloadTask.countOfBytesExpectedToReceive
        DispatchQueue.main.async {
            self.progressHandlers[url]?(1.0, totalBytes, totalBytes, 0)
        }

        let destination = URL(fileURLWithPath: destinationPath)
        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            DispatchQueue.main.async {
                self.completionHandlers[url]?(.success(destination))
            }
        } catch {
            DispatchQueue.main.async {
                self.completionHandlers[url]?(.failure(error))
            }
        }
        cleanup(url: url)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url else { return }
        if let error = error {
            DispatchQueue.main.async {
                self.completionHandlers[url]?(.failure(error))
            }
        }
        cleanup(url: url)
    }
    // Async/await wrapper for download
    func downloadFile(
        from url: URL,
        to destination: URL,
        progress: @escaping (Double, Int64, Int64, Int64) -> Void
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            var resumed = false
            let resumeQueue = DispatchQueue(label: "com.yahgs.download.resumeQueue")

            self.download(from: url, to: destination, progress: progress) { result in
                resumeQueue.async {
                    if resumed { return }
                    resumed = true
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            continuation.resume()
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                resumeQueue.async {
                    if !resumed {
                        resumed = true
                        continuation.resume(throwing: NSError(domain: "DownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载超时，续体未恢复"]))
                    }
                }
            }
        }
    }
}
