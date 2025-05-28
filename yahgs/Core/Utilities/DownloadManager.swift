//
//  DownloadManager.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

final class DownloadManager: NSObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()

    private var lastUpdateTime: [URL: Date] = [:]
    private var lastDownloadedBytes: [URL: Int64] = [:]
    private var lastDispatchTime: [URL: Date] = [:]

    private var progressHandlers: [URL: (Double, Int64, Int64, Int64) -> Void] = [:]
    private var completionHandlers: [URL: (Result<URL, Error>) -> Void] = [:]
    private var downloadTasks: [URL: URLSessionDownloadTask] = [:]
    private var resumeDataStore: [URL: Data] = [:]
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    func download(from url: URL, to destination: URL,
                  progress: @escaping (Double, Int64, Int64, Int64) -> Void,
                  completion: @escaping (Result<URL, Error>) -> Void) {

        progressHandlers[url] = progress
        completionHandlers[url] = completion

        // 使用 URLSessionDownloadTask 实现下载
        let task = session.downloadTask(with: url)
        task.taskDescription = destination.path
        downloadTasks[url] = task
        task.resume()
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {

        guard let url = downloadTask.originalRequest?.url,
              let progressHandler = progressHandlers[url] else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        let now = Date()
        let lastTime = lastUpdateTime[url] ?? now
        let lastBytes = lastDownloadedBytes[url] ?? 0
        let timeInterval = now.timeIntervalSince(lastTime)
        let byteDelta = totalBytesWritten - lastBytes
        let speedBytesPerSec = timeInterval > 0 ? Int64(Double(byteDelta) / timeInterval) : 0

        lastUpdateTime[url] = now
        lastDownloadedBytes[url] = totalBytesWritten

        let lastDispatch = lastDispatchTime[url]

        if lastDispatch == nil || now.timeIntervalSince(lastDispatch!) >= 0.3 {
            lastDispatchTime[url] = now
            DispatchQueue.main.async {
                progressHandler(progress, totalBytesWritten, totalBytesExpectedToWrite, speedBytesPerSec)
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {

        guard let destinationPath = downloadTask.taskDescription else { return }
        let destinationURL = URL(fileURLWithPath: destinationPath)
        let url = downloadTask.originalRequest?.url

        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            if let url = url, let completionHandler = completionHandlers[url] {
                DispatchQueue.main.async {
                    completionHandler(.success(destinationURL))
                }
                completionHandlers.removeValue(forKey: url)
                progressHandlers.removeValue(forKey: url)
                downloadTasks.removeValue(forKey: url)
                resumeDataStore.removeValue(forKey: url)
            }
        } catch {
            if let url = url, let completionHandler = completionHandlers[url] {
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
                completionHandlers.removeValue(forKey: url)
                progressHandlers.removeValue(forKey: url)
                downloadTasks.removeValue(forKey: url)
                resumeDataStore.removeValue(forKey: url)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error,
              let url = task.originalRequest?.url,
              let completionHandler = completionHandlers[url] else { return }
        DispatchQueue.main.async {
            completionHandler(.failure(error))
        }
        completionHandlers.removeValue(forKey: url)
        progressHandlers.removeValue(forKey: url)
        downloadTasks.removeValue(forKey: url)
        resumeDataStore.removeValue(forKey: url)
    }

    func pause(url: URL) {
        guard let task = downloadTasks[url] else {
            print("[DownloadManager] 暂停失败：任务不存在")
            return
        }

        task.cancel(byProducingResumeData: { data in
            if let data = data {
                self.resumeDataStore[url] = data
            }
            self.downloadTasks.removeValue(forKey: url)
            print("[DownloadManager] 已暂停下载任务：\(url.lastPathComponent)")
        })
    }

    func resume(url: URL) {
        guard let resumeData = resumeDataStore[url] else {
            print("[DownloadManager] 无可用断点数据，无法恢复：\(url.lastPathComponent)")
            return
        }

        let task = session.downloadTask(withResumeData: resumeData)
        task.taskDescription = url.path
        downloadTasks[url] = task
        resumeDataStore.removeValue(forKey: url)
        task.resume()
        print("[DownloadManager] 恢复下载任务：\(url.lastPathComponent)")
    }

    func cancel(url: URL) {
        downloadTasks[url]?.cancel()
        downloadTasks.removeValue(forKey: url)
        resumeDataStore.removeValue(forKey: url)
        print("[DownloadManager] 已取消下载任务：\(url.lastPathComponent)")
    }
}
