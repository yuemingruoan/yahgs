//
//  DownloadProgressView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//


import SwiftUI

enum DownloadState {
    case downloading
    case paused
    case completed
    case failed
}

struct DownloadProgressView: View {
    let title: String
    let cancelAction: (() -> Void)?
    let pauseAction: (() -> Void)?
    let resumeAction: (() -> Void)?
    let retryAction: (() -> Void)?
    let isCancelable: Bool
    let state: DownloadState
    let errorMessage: String?

    // 这些绑定属性由外部传入，确保实时更新下载进度和状态
    @Binding var progress: Double
    @Binding var downloaded: Int64
    @Binding var total: Int64
    @Binding var speed: Int64

    // 用于触发视图刷新
    @State private var refreshToggle = false

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatSpeed(_ bytesPerSecond: Int64) -> String {
        print("当前下载速率：\(bytesPerSecond) B/s")
        let kb = 1024.0
        let mb = kb * 1024
        let gb = mb * 1024
        let speed = Double(bytesPerSecond)

        func format(_ value: Double) -> String {
            if value >= 100 {
                return String(format: "%.0f", value)
            } else if value >= 10 {
                return String(format: "%.1f", value)
            } else {
                return String(format: "%.3g", value)
            }
        }

        if speed >= gb {
            let inGB = speed / gb
            let inMB = speed / mb
            if Int(inGB) < 10 {
                return "\(format(inMB)) MB/s"
            } else {
                return "\(format(inGB)) GB/s"
            }
        } else if speed >= mb {
            let inMB = speed / mb
            let inKB = speed / kb
            if Int(inMB) < 10 {
                return "\(format(inKB)) KB/s"
            } else {
                return "\(format(inMB)) MB/s"
            }
        } else if speed >= kb {
            return "\(format(speed / kb)) KB/s"
        } else {
            return "\(bytesPerSecond) B/s"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            if state == .completed {
                Text("下载完成")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 480)

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)

                Text("\(formatBytes(downloaded)) / \(formatBytes(total))（\(formatSpeed(speed))）")
                    .font(.caption)
                    .frame(width: 480)
            }

            if let message = errorMessage, state == .failed {
                Text("错误：\(message)")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 16) {
                if state == .downloading {
                    if let pause = pauseAction {
                        Button("暂停", action: pause)
                    }
                } else if state == .paused {
                    if let resume = resumeAction {
                        Button("继续", action: resume)
                    }
                } else if state == .completed {
                    Text("✓ 已完成")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else if state == .failed {
                    if let retry = retryAction {
                        Button("重试", action: retry)
                    }
                }

                if isCancelable, let cancel = cancelAction {
                    Button("取消", role: .destructive, action: cancel)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        // 强制刷新视图
        .onChange(of: state) { oldValue, newValue in
            print("下载状态变化：\(oldValue) -> \(newValue)")
            if newValue == .completed {
                refreshToggle.toggle()
            }
        }
        // 绑定一个不使用的状态以触发刷新
        .id(refreshToggle)
    }
}
