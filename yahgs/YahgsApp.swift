//
//  YahgsApp.swift
//  yahgs
//
//  Created by 时雨 on 2025/5/9.
//


import SwiftUI
import Foundation

enum AppLaunchPhase: Hashable {
    case welcome
    case launcher
}

// MARK: - 应用主入口
@main
struct YahgsApp: App {
    @StateObject private var launcherViewModel = LauncherViewModel()
    @State private var launchPhase: AppLaunchPhase = .welcome
    @State private var showSettings: Bool = false

    init() {
        createProjectFolder()
    }

    private func createProjectFolder() {
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let projectFolderURL = appSupportURL.appendingPathComponent("Yahgs")
            if !fileManager.fileExists(atPath: projectFolderURL.path) {
                do {
                    try fileManager.createDirectory(at: projectFolderURL, withIntermediateDirectories: true, attributes: nil)
                    print("Created project folder at: \(projectFolderURL.path)")
                } catch {
                    print("Failed to create project folder: \(error.localizedDescription)")
                }
            } else {
                print("Project folder already exists at: \(projectFolderURL.path)")
            }
        }
    }

    enum DownloadComponent: String, Hashable {
        case wine
        case dxmt
        case launcher
        case game
    }

    enum SettingsPage: Hashable, Equatable {
        case general
        case sectionInstaller(component: DownloadComponent)
    }
    
    @ViewBuilder
    private func activeView() -> some View {
        switch launchPhase {
        case .launcher:
            LauncherHomeView(onSettingsRequested: {
                showSettings = true
            })
                .onAppear {  }
                .ignoresSafeArea()
                .frame(minWidth: 960, minHeight: 540)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.move(edge: .trailing))
        case .welcome:
            WelcomeScreenView(isWelcomeFlowComplete: Binding(
                // isDone 为 true 时表示不再显示欢迎页
                get: { launchPhase != .welcome },
                set: { done in
                     
                    launchPhase = done ? .launcher : .welcome
                }
            ))
            .onAppear {  }
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
            .environmentObject(launcherViewModel)
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
