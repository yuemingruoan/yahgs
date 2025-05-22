//
//  WelcomeScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//

import SwiftUI

enum DownloadTarget {
    case wine
    case dxmt
}

struct WelcomeScreenView: View {
    @EnvironmentObject var launcherState: LauncherState
    @Binding var isDone: Bool
    @State private var step: Int = 1
    @State private var isDownloading = false
    @State private var isPaused: [DownloadTarget: Bool] = [.wine: false, .dxmt: false]
    @State private var downloadProgress: Double = 0.0
    @State private var downloadDownloaded: Int64 = 0
    @State private var downloadTotal: Int64 = 1
    @State private var downloadSpeed: Int64 = 0
    @State private var downloadState: DownloadState = .downloading
    @State private var installFailed = false
    @State private var currentStage: String = ""
    @State private var task: Task<Void, Never>?

    let downloadService = DownloadService()

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
                            DownloadProgressView(
                                title: "正在安装 Wine...",
                                cancelAction: { cancelInstall() },
                                pauseAction: {
                                    downloadService.pause(.wine)
                                    downloadState = .paused
                                    isPaused[.wine] = true
                                },
                                resumeAction: {
                                    downloadService.resume(.wine)
                                    downloadState = .downloading
                                    isPaused[.wine] = false
                                },
                                retryAction: {
                                    resetWineInstall()
                                },
                                isCancelable: true,
                                state: downloadState,
                                errorMessage: installFailed ? "下载失败，请重试" : nil,
                                progress: $downloadProgress,
                                downloaded: $downloadDownloaded,
                                total: $downloadTotal,
                                speed: $downloadSpeed
                            )
                            .padding()
                            .task {
                                if task == nil && !installFailed && !downloadProgress.isEqual(to: 1.0) {
                                    startWineInstall()
                                }
                            }
                            .onDisappear {
                                task?.cancel()
                                task = nil
                                isDownloading = false
                                isPaused[.wine] = false
                            }
                        case 4:
                            DownloadProgressView(
                                title: "正在安装 DXMT...",
                                cancelAction: { cancelInstall() },
                                pauseAction: {
                                    downloadService.pause(.dxmt)
                                    downloadState = .paused
                                    isPaused[.dxmt] = true
                                },
                                resumeAction: {
                                    downloadService.resume(.dxmt)
                                    downloadState = .downloading
                                    isPaused[.dxmt] = false
                                },
                                retryAction: {
                                    resetDxmtInstall()
                                },
                                isCancelable: true,
                                state: downloadState,
                                errorMessage: installFailed ? "下载失败，请重试" : nil,
                                progress: $downloadProgress,
                                downloaded: $downloadDownloaded,
                                total: $downloadTotal,
                                speed: $downloadSpeed
                            )
                            .padding()
                            .task {
                                if task == nil && !installFailed && !downloadProgress.isEqual(to: 1.0) {
                                    startDxmtInstall()
                                }
                            }
                            .onDisappear {
                                task?.cancel()
                                task = nil
                                isDownloading = false
                                isPaused[.dxmt] = false
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                HStack {
                    Spacer()
                    if isDownloading {
                        if step == 3 {
                            Button(isPaused[.wine] == true ? "继续" : "暂停") {
                                if let current = isPaused[.wine] {
                                    isPaused[.wine] = !current
                                } else {
                                    isPaused[.wine] = true
                                }
                            }
                        } else if step == 4 {
                            Button(isPaused[.dxmt] == true ? "继续" : "暂停") {
                                if let current = isPaused[.dxmt] {
                                    isPaused[.dxmt] = !current
                                } else {
                                    isPaused[.dxmt] = true
                                }
                            }
                        }
                        Button("取消") {
                            cancelInstall()
                        }
                    } else {
                        if step > 1 {
                            Button("Back") {
                                step -= 1
                            }
                        }
                        if step == 3 {
                            Button("Next") {
                                step += 1
                            }
                        } else if step == 4 {
                            Button("完成") {
                                launcherState.settings.hasSeenWelcome = true
                                launcherState.saveSettings()
                                isDone = true
                            }
                        } else if step < 3 {
                            Button("Next") {
                                step += 1
                            }
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

    func startWineInstall() {
        isDownloading = true
        installFailed = false
        downloadProgress = 0
        currentStage = ""
        downloadState = .downloading
        isPaused[.wine] = false
        task = Task {
            do {
                try await downloadService.install(.wine) { percent, downloaded, total, speed in
                    downloadProgress = percent
                    downloadDownloaded = downloaded
                    downloadTotal = total
                    downloadSpeed = speed
                    currentStage = "Wine"
                }
                if !(task?.isCancelled ?? true) && !installFailed {
                    await MainActor.run {
                        downloadProgress = 1.0
                        isDownloading = false
                        isPaused[.wine] = false
                        downloadState = .completed
                        step = 4
                    }
                }
            } catch {
                await MainActor.run {
                    installFailed = true
                    isDownloading = false
                    isPaused[.wine] = false
                    downloadState = .failed
                }
            }
        }
    }

    func startDxmtInstall() {
        isDownloading = true
        installFailed = false
        downloadProgress = 0
        currentStage = ""
        downloadState = .downloading
        isPaused[.dxmt] = false
        task = Task {
            do {
                try await downloadService.install(.dxmt) { percent, downloaded, total, speed in
                    downloadProgress = percent
                    downloadDownloaded = downloaded
                    downloadTotal = total
                    downloadSpeed = speed
                    currentStage = "DXMT"
                }
                await MainActor.run {
                    downloadProgress = 1.0
                    isDownloading = false
                    isPaused[.dxmt] = false
                    downloadState = .completed
                }
            } catch {
                await MainActor.run {
                    installFailed = true
                    isDownloading = false
                    isPaused[.dxmt] = false
                    downloadState = .failed
                }
            }
        }
    }

    func cancelInstall() {
        task?.cancel()
        task = nil
        installFailed = true
        isDownloading = false
        isPaused[.wine] = false
        isPaused[.dxmt] = false
        if step == 3 {
            downloadService.cancel(.wine)
        } else if step == 4 {
            downloadService.cancel(.dxmt)
        } else {
            // 不调用取消，或者根据需求自行处理
        }
    }

    func resetWineInstall() {
        downloadProgress = 0
        installFailed = false
        isPaused[.wine] = false
        isDownloading = true
        startWineInstall()
    }

    func resetDxmtInstall() {
        downloadProgress = 0
        installFailed = false
        isPaused[.dxmt] = false
        isDownloading = true
        startDxmtInstall()
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
    @EnvironmentObject var launcherState: LauncherState

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
