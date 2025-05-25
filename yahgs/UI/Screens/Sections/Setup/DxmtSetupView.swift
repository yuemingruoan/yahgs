//
//  DxmtSetupView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//


import SwiftUI
import Foundation

struct DxmtSetupView: View {
    @StateObject private var setupVM: SetupViewModel
    var onCompletion: (() -> Void)?

    init(onCompletion: (() -> Void)? = nil) {
        _setupVM = StateObject(wrappedValue: SetupViewModel(
            component: .dxmt,
            downloadDestination: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Yahgs/dxmt.tar.xz")
        ))
        self.onCompletion = onCompletion
    }

    var body: some View {
        VStack(spacing: 40) {
            Text("DXMT 安装进度")
                .font(.title2)
                .bold()
                .padding(.top, 20)

            if setupVM.currentStep == .idle || setupVM.currentStep == .downloading {
                ProgressViewCard(
                    title: "正在下载 DXMT",
                    phaseDescription: "下载中...",
                    progressSource: .binding(setupVM.downloadProgressBinding),
                    downloadedSize: setupVM.downloadVM.downloadedSize,
                    totalSize: setupVM.downloadVM.totalSize,
                    speed: setupVM.downloadVM.speed
                )
            }

            if setupVM.currentStep == .operating || setupVM.currentStep == .completed {
                ProgressViewCard(
                    title: "正在配置 DXMT",
                    phaseDescription: setupVM.operationVM.phaseDescription,
                    progressSource: .binding(setupVM.operationProgressBinding),
                    downloadedSize: nil,
                    totalSize: nil,
                    speed: nil
                )
            }

            if let error = setupVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding(.top, 20)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            setupVM.start()
        }
        .onChange(of: setupVM.downloadProgressBinding.wrappedValue) { newValue, _ in
            print("[DxmtSetupView] download progress: \(newValue)")
        }
        .onChange(of: setupVM.currentStep) { newStep, _ in
            if newStep == .completed {
                onCompletion?()
            }
        }
    }
}
