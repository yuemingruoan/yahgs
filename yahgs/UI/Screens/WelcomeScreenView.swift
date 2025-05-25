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
    @State private var currentStep: WelcomeStep = .welcome  // .splash 可用于后续补充启动动画

    var body: some View {
        switch currentStep {
        case .splash:
            Color.white // 占位，后续可替换为 SplashView
                .onAppear {
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
            WineSetupView(onCompletion: {
                currentStep = .dxmtSetup
            })

        case .dxmtSetup:
            DxmtSetupView(onCompletion: {
                isWelcomeFlowComplete = true
            })

        case .done:
            EmptyView()
        }
    }
}
