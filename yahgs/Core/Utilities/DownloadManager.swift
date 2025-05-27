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
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    func download(from url: URL, to destination: URL,
                  progress: @escaping (Double, Int64, Int64, Int64) -> Void,
                  completion: @escaping (Result<URL, Error>) -> Void) {

        progressHandlers[url] = progress
        completionHandlers[url] = completion

        // 原 aria2c 代码注释开始
        /*
        let destinationDirectory = destination.deletingLastPathComponent().path
        let fileName = destination.lastPathComponent

        // 启动 aria2c 下载
        let process = Process()
        guard let aria2cPath = Bundle.main.path(forResource: "aria2c", ofType: nil) else {
            print("[DownloadManager] Error: aria2c not found in app bundle")
            completion(.failure(NSError(domain: "Aria2cNotFound", code: -1)))
            return
        }
        process.executableURL = URL(fileURLWithPath: aria2cPath)
        process.arguments = [
            "--dir=\(destinationDirectory)",
            "--out=\(fileName)",
            "--allow-overwrite=true",
            "--summary-interval=1",
            "--follow-metalink=mem",
            "--follow-torrent=mem",
            "--enable-http-keep-alive=true",
            "--max-connection-per-server=4",
            "--check-certificate=false",
            "--auto-file-renaming=false",
            "--header=User-Agent: Mozilla/5.0",
            url.absoluteString
        ]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else {
                return
            }
            output.enumerateLines { line, _ in
                print("[aria2c] \(line)")
                if let info = Aria2ProgressParser.parseProgress(from: line) {
                    DispatchQueue.main.async {
                        progress(info.percent, info.downloadedBytes, info.totalBytes, info.speedBytesPerSec)
                    }
                }
            }
        }

        print("[DownloadManager] Launching aria2c at: \(process.executableURL?.path ?? "nil")")
        print("[DownloadManager] With arguments: \(process.arguments?.joined(separator: " ") ?? "nil")")

        do {
            try process.run()
        } catch {
            completion(.failure(error))
            return
        }

        process.terminationHandler = { proc in
            DispatchQueue.main.async {
                completion(.success(destination))
            }
        }
        */
        // 原 aria2c 代码注释结束

        // 使用 URLSessionDownloadTask 实现下载
        let task = session.downloadTask(with: url)
        task.taskDescription = destination.path
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
            }
        } catch {
            if let url = url, let completionHandler = completionHandlers[url] {
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
                completionHandlers.removeValue(forKey: url)
                progressHandlers.removeValue(forKey: url)
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
    }

    func pause(url: URL) {
        print("[DownloadManager] 暂停下载功能不支持")
    }

    func resume(url: URL) {
        print("[DownloadManager] 继续下载功能不支持")
    }

    func cancel(url: URL) {
        print("[DownloadManager] 取消下载功能不支持")
    }
}
