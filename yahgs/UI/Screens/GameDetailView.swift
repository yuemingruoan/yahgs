//
//  GameDetailView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/10.
//

import SwiftUI

struct GameDetailView: View {
    let item: NavItem
    @EnvironmentObject var launcherState: GameLauncherState
    @State private var isPinHover = false
    @State private var isStartHover = false
    @State private var isSettingHover = false
    
    var isPinned: Bool {
        launcherState.settings.pinnedGame == item.title
    }
    
    var body: some View {
        ZStack {
            // 按钮与文本
            VStack {
                Spacer()
                HStack {
                    // 左下角游戏信息
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        if let version = launcherState.settings.gameVersions[item.title] {
                            Text("版本：\(version)")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    Spacer()
                    // 右下角按钮
                    HStack(spacing: 16) {
                        Button(action: {
                            // 启动游戏逻辑
                        }) {
                            Text("开始游戏")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 28)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(item.themeColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in isStartHover = hovering }

                        Button(action: {
                            let settingsWindow = NSWindow(
                                contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                                styleMask: [.titled, .closable, .resizable],
                                backing: .buffered, defer: false)
                            settingsWindow.center()
                            settingsWindow.title = "设置"
                            settingsWindow.titleVisibility = .hidden
                            settingsWindow.titlebarAppearsTransparent = true
                            settingsWindow.isReleasedWhenClosed = false
                            settingsWindow.contentView = NSHostingView(
                                rootView: SettingsScreenView().environmentObject(launcherState)
                            )
                            settingsWindow.makeKeyAndOrderFront(nil)
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(item.themeColor)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in isSettingHover = hovering }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }

            // 右上角 PIN 按钮
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if isPinned {
                            launcherState.updatePinnedGame(to: "")
                        } else {
                            launcherState.updatePinnedGame(to: item.title)
                        }
                    }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(isPinHover ? item.themeColor : .white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.4))
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in isPinHover = hovering }
                    .padding(20)
                }
                Spacer()
            }
        }
        .frame(width: 780, height: 540)
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}
