//
//  LauncherHomeView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//

import SwiftUI

// MARK: - 启动器主界面入口
struct LauncherHomeView: View {
    @EnvironmentObject var launcherState: LauncherState
    @State private var selectedItem: NavItem?
    @State private var navItems: [NavItem] = []

    var onSettingsRequested: () -> Void

    private static func generateNavItems(from settings: LauncherSettings) -> [NavItem] {
        let gameTitles = ["原神", "崩坏：星穹铁道", "绝区零"]
        let gameIcons = ["sparkle", "tram.fill", "bolt.fill"]
        let gameCoverImages = ["genshin_cover", "starrail_cover", "zzz_cover"]

        return gameTitles.enumerated().map { index, title in
            let colorString = settings.gameThemeColors[title] ?? ""
            let themeColor = Color(hex: colorString) ?? .gray
            return NavItem(title: title, icon: gameIcons[index], themeColor: themeColor, coverImage: gameCoverImages[index])
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // MARK: - 背景图层
                    LauncherBgLayer(launcherState: launcherState, selectedItem: selectedItem, size: geo.size)
                    // MARK: - 内容区
                    HStack(spacing: 0) {
                        // MARK: - 左侧导航栏
                        VStack(spacing: 16) {
                            ForEach(navItems) { item in
                                HoverGameButton(item: item, selectedItem: $selectedItem, setSelectedItem: setSelectedItem)
                            }
                            Spacer()
                        }
                        .padding(.top, 28)
                        .padding(.bottom)
                        .frame(minWidth: 190, maxWidth: geo.size.width * 0.2)
                        .background(
                            VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                        )
                        .ignoresSafeArea() // 确保左侧导航栏充满整个屏幕高度

                        // MARK: - 启动器游戏详情组件
                        if let selectedItem {
                            LauncherGameDetailView(item: selectedItem, onSettingsRequested: onSettingsRequested)
                                .ignoresSafeArea() // 右侧内容区充满剩余屏幕
                                .environmentObject(launcherState)
                        } else {
                            Text("未选择游戏")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white)
                                .ignoresSafeArea() // 右侧区域充满剩余屏幕
                        }
                    }
                }
            }
        }
        .onAppear {
            let settings = launcherState.settings
            let items = LauncherHomeView.generateNavItems(from: settings)
            navItems = items
            if let pinned = settings.pinnedGame, let match = items.first(where: { $0.title == pinned }) {
                selectedItem = match
            } else if let last = settings.lastSelectedGame, let match = items.first(where: { $0.title == last }) {
                selectedItem = match
            } else {
                selectedItem = items.first
            }
        }
    }

    private func setSelectedItem(_ item: NavItem) {
        selectedItem = item
        launcherState.updateLastSelectedGame(to: item.title)
    }
}

// 带 hover 效果的导航按钮
private struct HoverGameButton: View {
    let item: NavItem
    @Binding var selectedItem: NavItem?
    let setSelectedItem: (NavItem) -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: {
            setSelectedItem(item)
        }) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(item.themeColor)
                Text(item.title)
                    .font(.title3)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        item == selectedItem ? item.themeColor.opacity(0.2) :
                        (isHovering ? item.themeColor.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - 启动器游戏详情组件
struct LauncherGameDetailView: View {
    let item: NavItem
    @EnvironmentObject var launcherState: LauncherState
    @State private var isPinHover = false
    @State private var isStartHover = false
    @State private var isSettingHover = false
    
    var isPinned: Bool {
        launcherState.settings.pinnedGame == item.title
    }
    
    var onSettingsRequested: () -> Void

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
                            onSettingsRequested()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(16)
        .shadow(radius: 8)
    }
}


extension LauncherHomeView {
    // MARK: - 背景图层
    struct LauncherBgLayer: View {
        let launcherState: LauncherState
        let selectedItem: NavItem?
        let size: CGSize
        
        var body: some View {
            if let bgPath = launcherState.settings.customBackgroundPaths[selectedItem?.title ?? ""],
               let nsImage = NSImage(contentsOfFile: bgPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
            } else {
                Image("default_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
            }
        }
    }
}

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 6 else {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}
