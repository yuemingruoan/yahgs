//
//  WelcomeScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//

import SwiftUI
import Foundation

enum WelcomeStep {
    case splash
    case welcome
    case agreement
    case wineSetup
    case dxmtSetup
    case done
}

struct WelcomeScreenView: View {
    @Binding var isWelcomeFlowComplete: Bool
    @State private var currentStep: WelcomeStep = .splash  // 初始为 splash 展示启动动画

    var body: some View {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let yahgsDir = appSupportDir.appendingPathComponent("yahgs", isDirectory: true)

        switch currentStep {
        case .splash:
            ZStack {
                Color.white
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    Text("启动中...")
                        .font(.headline)
                        .padding(.top, 8)
                }
            }
            .onAppear {
                // 确保目录存在
                try? FileManager.default.createDirectory(at: yahgsDir, withIntermediateDirectories: true)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    currentStep = .welcome
                }
            }
        case .welcome:
            WelcomeStepWelcome {
                currentStep = .agreement
            }
        case .agreement:
            WelcomeStepAgreement()
                .overlay(
                    VStack {
                        Spacer()
                        Button("我已阅读并同意以上内容，继续") {
                            currentStep = .wineSetup
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 30)
                    }
                )
        case .wineSetup:
            SetupView(component: .wine, downloadDestination: yahgsDir.appendingPathComponent("wine.tar.xz")) {
                currentStep = .dxmtSetup
            }
        case .dxmtSetup:
            SetupView(component: .dxmt, downloadDestination: yahgsDir.appendingPathComponent("dxmt.tar.gz")) {
                isWelcomeFlowComplete = true
            }
        case .done:
            EmptyView()
        }
    }
}
