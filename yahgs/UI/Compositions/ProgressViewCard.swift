//
//  ProgressViewCard.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//


import SwiftUI
import Foundation

/// 展示型组件：用于展示操作或下载任务进度
struct ProgressViewCard: View {
    let title: String
    let progress: Double
    let downloadedSize: String?
    let totalSize: String?
    let speed: String?

    private let fixedInfoWidth: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题 居中显示
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            ZStack(alignment: .topLeading) {
                // 进度条及其背景
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 20)
                    .padding(.top, 20) // 给顶部信息留空间

                // 左上角：下载大小和速度
                HStack(spacing: 12) {
                    if let downloaded = downloadedSize, let total = totalSize {
                        Text("\(downloaded) / \(total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: fixedInfoWidth, alignment: .leading)
                            .lineLimit(1)
                    } else {
                        Spacer().frame(width: fixedInfoWidth)
                    }

                    if let speed = speed {
                        Text(speed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: fixedInfoWidth, alignment: .leading)
                            .lineLimit(1)
                    } else {
                        Spacer().frame(width: fixedInfoWidth)
                    }
                }
                .padding(.leading, 4)
                .padding(.top, 2)

                // 右上角：百分比进度
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, alignment: .trailing)

            }
            .frame(height: 60)
        }
        .frame(width: 720, height: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.white))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
}
