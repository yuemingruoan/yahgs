//
//  SectionInstallerView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//

import SwiftUI

enum InstallableComponent: String {
    case wine = "Wine"
    case dxmt = "DXMT"
}

struct SectionInstallerView: View {
    let component: InstallableComponent
    @State private var progress: Double = 0
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("正在下载：\(component.rawValue) 0.51")
                .font(.headline)

            Text(String(format: "已下载 %.2fMB / %.2fMB", progress / 100 * 56.78, 56.78))
                .font(.subheadline)

            Text(String(format: "%.2f%%", progress))
                .font(.subheadline)

            ProgressView(value: progress, total: 100)
                .progressViewStyle(LinearProgressViewStyle())
                .animation(.easeOut, value: progress)

            Text("下载速率：1.25 MB/s")
                .font(.footnote)
                .foregroundColor(.gray)

            HStack(spacing: 12) {
                if progress > 0 && progress < 100 {
                    Button("暂停") {
                        // 暂停逻辑
                    }
                } else if progress == 0 {
                    Button("开始安装") {
                        // 开始逻辑
                    }
                } else if progress < 100 {
                    Button("重新下载") {
                        // 重新逻辑
                    }
                    Button("取消") {
                        // 取消逻辑
                    }
                }
                Button("关闭") {
                    onDismiss()
                }
            }
        }
        .padding()
        .frame(width: 600)
    }
}
