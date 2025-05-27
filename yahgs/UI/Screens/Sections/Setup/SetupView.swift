//
//  SetupView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/28.
//

import SwiftUI

struct SetupView: View {
    let component: DownloadComponent
    let downloadDestination: URL

    @StateObject private var downloadVM = DownloadViewModel()
    @StateObject private var operationVM: OperationViewModel

    @State private var errorMessage: String?

    var onCompletion: (() -> Void)?

    init(component: DownloadComponent, downloadDestination: URL, onCompletion: (() -> Void)? = nil) {
        self.component = component
        self.downloadDestination = downloadDestination
        self.onCompletion = onCompletion
        let sharedDownloadVM = DownloadViewModel()
        _downloadVM = StateObject(wrappedValue: sharedDownloadVM)
        _operationVM = StateObject(wrappedValue: OperationViewModel(component: component, downloadDestination: downloadDestination, downloadVM: sharedDownloadVM))
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("\(component.rawValue.uppercased()) 安装进度")
                .font(.title2)
                .bold()
                .padding(.top, 20)

            if downloadVM.progress < 1.0 {
                ProgressViewCard(
                    title: "正在下载 \(component.rawValue.uppercased())",
                    progress: downloadVM.progress,
                    downloadedSize: downloadVM.downloadedSize,
                    totalSize: downloadVM.totalSize,
                    speed: downloadVM.speed
                )
            } else if operationVM.progress < 1.0 {
                ProgressViewCard(
                    title: "正在配置 \(component.rawValue.uppercased())",
                    progress: operationVM.progress,
                    downloadedSize: nil,
                    totalSize: nil,
                    speed: nil
                )
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            errorMessage = nil
            Task {
                await downloadVM.reset()
                operationVM.reset()
                do {
                    try await downloadVM.startDownload(component: component, to: downloadDestination)
                    operationVM.startOperation()
                } catch {
                    errorMessage = error.localizedDescription
                    print("[SetupView] Error: \(error.localizedDescription)")
                }
            }
        }
        .onChange(of: downloadVM.progress) {
            print("[SetupView] download progress: \(downloadVM.progress)")
        }
        .onChange(of: operationVM.progress) {
            if operationVM.progress >= 1.0 {
                onCompletion?()
            }
        }
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView(component: .wine, downloadDestination: FileManager.default.temporaryDirectory)
    }
}
