//
//  WelcomeScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//

import SwiftUI

struct WelcomeScreenView: View {
    @EnvironmentObject var launcherState: GameLauncherState
    @Binding var isDone: Bool
    @State private var step: Int = 1

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.ignoresSafeArea()

                VStack(spacing: 20) {
                    // 右上角语言选择，仅第二步显示
                    if step == 2 {
                        HStack {
                            Spacer()
                            WelcomeLanguageSection()
                                .frame(width: 300)
                                .padding(.top, 10)
                                .padding(.trailing, 10)
                        }
                    }

                    // 主要内容
                    Group {
                        switch step {
                        case 1:
                            Text("欢迎使用YAHGS启动器！")
                                .font(.largeTitle)
                                .padding()
                        case 2:
                            WelcomeAgreementSection()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case 3:
                            WelcomeWineSection()
                        default:
                            EmptyView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Spacer()
                    if step > 1 {
                        Button("Back") {
                            step -= 1
                        }
                    }
                    if step < 3 {
                        Button("Next") {
                            step += 1
                        }
                    } else {
                        Button("完成") {
                            launcherState.settings.hasSeenWelcome = true
                            launcherState.settings.save()
                            isDone = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .ignoresSafeArea()
        }
        .frame(minWidth: 960, minHeight: 540)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SplashSection (已注释)
// struct SplashSection: View {
//     var body: some View {
//         VStack {
//             Spacer()
//             Text("YAHGS 正在启动...")
//                 .font(.largeTitle)
//                 .opacity(0.7)
//             Spacer()
//         }
//         .frame(maxWidth: .infinity, maxHeight: .infinity)
//         .background(Color.black.opacity(0.05))
//     }
// }

// MARK: - WelcomeLanguageSection
struct WelcomeLanguageSection: View {
    @EnvironmentObject var launcherState: GameLauncherState

    var body: some View {
        HStack(spacing: 8) {
            Text("语言 Language")
                .font(.headline)
            Picker("Language", selection: $launcherState.settings.preferredLanguage) {
                Text("中文").tag("zh")
                Text("日本語").tag("ja")
                Text("English").tag("en")
                Text("Français").tag("fr")
            }
            .labelsHidden()
            .frame(width: 140)
        }
        .padding()
    }
}

// MARK: - WelcomeWineSection
struct WelcomeWineSection: View {
    @EnvironmentObject var launcherState: GameLauncherState
    @State private var installing = true

    var body: some View {
        VStack {
            if installing {
                // ProgressView("正在安装 Wine 和 DXMT...")
                //     .padding()
                Text("安装功能已禁用")
                    .padding()
            } else {
                Text("安装完成！")
                    .padding()
            }
        }
        .onAppear {
//            Task {
//                do {
//                    try await InstallWine { _ in }
//                    try await DxmtInstaller().install()
//                } catch {
//                    print("安装失败：\(error)")
//                }
                installing = false
//            }
        }
    }
}
