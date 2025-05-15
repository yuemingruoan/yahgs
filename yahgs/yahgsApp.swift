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
            ContentView()
                .ignoresSafeArea()
                .environmentObject(launcherState)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .defaultSize(width: 960, height: 540)
        .windowResizability(.contentSize)
        .windowToolbarStyle(UnifiedWindowToolbarStyle())
        .commands {
            CommandGroup(replacing: .appInfo) {}
            CommandGroup(replacing: .windowList) {}
        }
    }
}
