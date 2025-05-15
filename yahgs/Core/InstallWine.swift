//
//  InstallWine.swift
//  yahgs
//
//  Created by 时雨 on 2025/5/9.
//

import Foundation
import Zip

// 下载进度追踪器
class DownloadProgressTracker: NSObject, URLSessionDataDelegate {
    private var totalBytesExpected: Int64 = 0
    private var totalBytesReceived: Int64 = 0
    private var downloadedData = Data()
    private var completion: ((Result<Data, Error>) -> Void)?
    
    // 每秒打印进度
    private var progressTimer: Task<Void, Never>?
    
    func startTrackingProgress() {
        progressTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
                guard let self = self, self.totalBytesExpected > 0 else { continue }
                let percentage = Double(self.totalBytesReceived) / Double(self.totalBytesExpected) * 100
                print("Download progress: \(String(format: "%.2f", percentage))%")
            }
        }
    }
    
    func stopTrackingProgress() {
        progressTimer?.cancel()
    }
    
    // URLSessionDataDelegate: 接收响应，获取总大小
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            completionHandler(.cancel)
            completion?(.failure(URLError(.badServerResponse)))
            return
        }
        totalBytesExpected = response.expectedContentLength
        completionHandler(.allow)
    }
    
    // URLSessionDataDelegate: 接收数据块
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloadedData.append(data)
        totalBytesReceived += Int64(data.count)
    }
    
    // URLSessionDataDelegate: 下载完成
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        stopTrackingProgress()
        if let error = error {
            completion?(.failure(error))
        } else {
            completion?(.success(downloadedData))
        }
    }
    
    // 开始下载
    func download(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        self.completion = completion
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: url)
        startTrackingProgress()
        task.resume()
        session.finishTasksAndInvalidate()
    }
}

public func InstallWine() async throws {
    // 创建用于下载的 URLSession
    guard let download_url = URL(string: "https://vip.123pan.cn/1838809579/%E7%B1%B3%E6%B8%B8%E8%AE%BE%E7%BD%AE%E5%99%A8/wine.zip") else {
        throw URLError(.badURL)
    }
    
    // 使用进度追踪器下载
    let tracker = DownloadProgressTracker()
    let data = try await withCheckedThrowingContinuation { continuation in
        tracker.download(from: download_url) { result in
            switch result {
            case .success(let data):
                continuation.resume(returning: data)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
    
    // 获取应用的 Application Support 目录 URL
    guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        throw URLError(.fileDoesNotExist)
    }
    
    // 创建 yahgs 文件夹的 URL
    let yahgsURL = appSupportURL.appendingPathComponent("yahgs")
    
    // 检查 yahgs 文件夹是否存在，如果不存在则创建
    try FileManager.default.createDirectory(at: yahgsURL, withIntermediateDirectories: true)
    
    // 创建目标文件 URL
    let fileName = download_url.lastPathComponent
    let destinationURL = yahgsURL.appendingPathComponent(fileName)
    
    // 将下载的数据写入 yahgs 目录
    try data.write(to: destinationURL)
    print("File saved to: \(destinationURL.path)")
    
    // 创建 wine 文件夹的 URL
    let wineURL = yahgsURL.appendingPathComponent("wine")
    
    // 检查 wine 文件夹是否存在，如果不存在则创建
    try FileManager.default.createDirectory(at: wineURL, withIntermediateDirectories: true)
    
    // 解压 zip 文件到 wine 文件夹
    do {
        try Zip.unzipFile(destinationURL, destination: wineURL, overwrite: true, password: nil)
        print("File unzipped to: \(wineURL.path)")
        
        // 可选：解压后删除原始 zip 文件
        try FileManager.default.removeItem(at: destinationURL)
        print("Original zip file removed")
    } catch {
        throw error
    }
}
