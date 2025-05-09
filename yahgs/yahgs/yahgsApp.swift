//
//  yahgsApp.swift
//  yahgs
//
//  Created by 时雨 on 2025/5/9.
//

import SwiftUI

@main
struct yahgsApp: App {
    @StateObject private var launcherState = GameLauncherState()

    var body: some Scene {
        WindowGroup {
            ContentView() // 加载实际视图
                .environmentObject(launcherState) // 传递 environmentObject
        }
        .commands {
            CommandGroup(replacing: .newItem) {} // 移除新建窗口菜单
        }

        Settings {} // 防止默认设置窗口
    }

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 960, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "YAHGS 启动器"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView().environmentObject(launcherState)) // 保证窗口内容
        window.isOpaque = false
        window.hasShadow = true
        window.styleMask.remove(.resizable) // 禁止缩放
        window.collectionBehavior.remove(.fullScreenPrimary) // 禁用全屏
        window.makeKeyAndOrderFront(nil)
    }
}
