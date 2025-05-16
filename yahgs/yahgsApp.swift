//
//  yahgsApp.swift
//  yahgs
//
//  Created by 时雨 on 2025/5/9.
//

import SwiftUI

// MARK: - 应用主入口
@main
struct yahgsApp: App {
    @StateObject private var launcherState = GameLauncherState()
    @State private var launchPhase: AppLaunchPhase = .welcome
    @State private var showSettings: Bool = false

    // MARK: - 启动阶段枚举
    enum AppLaunchPhase: Hashable {
        case welcome
        case launcher
    }

    enum SettingsPage: Hashable {
        case general
        case sectionInstaller(component: InstallableComponent)
    }
    
    @ViewBuilder
    private func activeView() -> some View {
        switch launchPhase {
        case .launcher:
            LauncherHomeView(onSettingsRequested: {
                showSettings = true
            })
                .onAppear { print("显示 LauncherHomeView") }
                .ignoresSafeArea()
                .frame(minWidth: 960, minHeight: 540)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing))
        case .welcome:
            WelcomeScreenView(isDone: Binding(
                // isDone 为 true 时表示不再显示欢迎页
                get: { launchPhase != .welcome },
                set: { done in
                    print("切换到 \(done ? "launcher" : "welcome") 阶段")
                    launchPhase = done ? .launcher : .welcome
                }
            ))
            .onAppear { print("显示 WelcomeScreenView") }
            .frame(minWidth: 960, minHeight: 540)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .transition(.move(edge: .leading))
        }
    }

    // MARK: - 主视图内容
    var body: some Scene {
        WindowGroup {
            ZStack {
                activeView()
                    .id(launchPhase)
                if showSettings {
                    GeometryReader { proxy in
                        let screenSize = proxy.size
                        let aspectRatio: CGFloat = 16.0 / 9.0
                        let width = min(screenSize.width, screenSize.height * aspectRatio)
                        let height = width / aspectRatio

                        ZStack {
                            Color.black.opacity(0.4)
                                .ignoresSafeArea()
                            ZStack {
                                Color.white.ignoresSafeArea()
                                SettingScreenView(onDismiss: {
                                    showSettings = false
                                })
                                .frame(width: width, height: height)
                                .transition(.opacity)
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
            }
            .environmentObject(launcherState)
        }
        // MARK: - 窗口样式配置
        .defaultSize(width: 960, height: 540)
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            CommandGroup(replacing: .appInfo) {}
            CommandGroup(replacing: .windowList) {}
        }
    }
}
