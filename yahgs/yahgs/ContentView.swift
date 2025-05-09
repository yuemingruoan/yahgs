import SwiftUI
import AppKit

struct NavItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let themeColor: Color
    let coverImage: String
}

struct ContentView: View {
    // 导航数据
    private let navItems = [
        NavItem(title: "原神", icon: "leaf", themeColor: .cyan, coverImage: "genshin_cover"),
        NavItem(title: "星穹铁道", icon: "star", themeColor: .purple, coverImage: "starrail_cover"),
        NavItem(title: "绝区零", icon: "bolt", themeColor: .orange, coverImage: "zzz_cover")
    ]
    
    @State private var selectedItem: NavItem?
    @State private var showSettings = false
    @EnvironmentObject var launcherState: GameLauncherState

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左侧导航栏
                List {
                    ForEach(navItems) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            NavigationRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(
                            selectedItem?.id == item.id ?
                            item.themeColor.opacity(0.15) :
                            Color.clear
                        )
                    }

                    // 恢复设置按钮
                    Button {
                        let settingsWindow = NSWindow(
                            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                            styleMask: [.titled, .closable, .resizable],
                            backing: .buffered, defer: false)
                        settingsWindow.center()
                        settingsWindow.title = "设置"
                        settingsWindow.titleVisibility = .hidden
                        settingsWindow.titlebarAppearsTransparent = true
                        settingsWindow.isReleasedWhenClosed = false
                        settingsWindow.contentView = NSHostingView(rootView: SettingsScreenView().environmentObject(launcherState))
                        settingsWindow.makeKeyAndOrderFront(nil)
                    } label: {
                        HStack {
                            Image(systemName: "gearshape")
                                .frame(width: 24)
                            Text("设置")
                            Spacer()
                        }
                        .foregroundColor(.primary)
                        .padding(10)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .padding(.top, 20)
                }
                .listStyle(.sidebar)
                .frame(width: 180)
                .background(Color("SidebarBackground"))
                
                // 右侧内容区
                ZStack {
                    if let selectedItem = selectedItem {
                        GameDetailView(item: selectedItem)
                            .transition(.opacity.combined(with: .slide))
                    } else {
                        PlaceholderView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color("ContentBackground"))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        // 移除 sheet(isPresented: $showSettings)
    }
}

struct NavigationRow: View {
    let item: NavItem
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.themeColor)
                .frame(width: 24)
            
            Text(item.title)
                .foregroundColor(.primary)
                .font(.headline)
            
            Spacer()
            
            if isHovered {
                Circle()
                    .fill(item.themeColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? item.themeColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    item.themeColor.opacity(isHovered ? 0.3 : 0),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct GameDetailView: View {
    let item: NavItem
    @EnvironmentObject var launcherState: GameLauncherState
    @State private var isHoveringStartButton = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Removed background image
            
            // 顶部右上角的“设为优先启动”按钮
            HStack {
                Spacer()
                Button("设为优先启动") {
                    // 实现优先启动逻辑
                    print("Set \(item.title) as priority launch.")
                }
                .padding()
            }
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            
            // Removed cover image
            
            // 底部左侧的游戏版本信息
            VStack {
                Spacer()
                HStack {
                    if let progress = launcherState.updateProgresses[item.title] {
                        ProgressView(value: progress) {
                            HStack {
                                Text("更新进度")
                                Text("\(Int(progress * 100))%")
                            }
                        }
                        .tint(item.themeColor)
                        .frame(width: 300)
                        
                        Button("暂停更新") {
                            launcherState.updateProgresses.removeValue(forKey: item.title)
                        }
                        .foregroundColor(item.themeColor)
                    } else {
                        Text("已安装版本：\(launcherState.gameVersions[item.title] ?? "1.0.0")")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 20)
            
            // 底部右侧的启动按钮，比版本信息略高
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: launchGame) {
                        Label("开始游戏", systemImage: "play.fill")
                            .font(.title2.bold())
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .background(
                                item.themeColor.gradient
                                    .shadow(.inner(color: .white.opacity(0.2), radius: 5, x: 0, y: 2))
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5) // 额外阴影
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isHoveringStartButton ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHoveringStartButton)
                    .onHover { hovering in
                        isHoveringStartButton = hovering
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 50)
                }
            }
        }
        .padding(.top, 50)
    }
    
    private func launchGame() {
        // 实际启动逻辑
        if launcherState.updateProgresses[item.title] == nil {
            print("Launching \(item.title)...")
        }
    }

    private func backgroundImageName(for title: String) -> String {
        switch title {
        case "原神":
            return "genshin_bg"
        case "星穹铁道":
            return "starrail_bg"
        case "绝区零":
            return "zenless_bg"
        default:
            return "default_bg" // 或者空字符串/备用背景
        }
    }
}
