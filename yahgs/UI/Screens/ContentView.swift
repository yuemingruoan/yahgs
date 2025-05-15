import SwiftUI

struct ContentView: View {
    private let navItems = [
        NavItem(title: "原神", icon: "sparkle", themeColor: .cyan, coverImage: "genshin_cover"),
        NavItem(title: "星穹铁道", icon: "tram.fill", themeColor: .purple, coverImage: "starrail_cover"),
        NavItem(title: "绝区零", icon: "bolt.fill", themeColor: .orange, coverImage: "zzz_cover")
    ]
    
    @EnvironmentObject var launcherState: GameLauncherState
    @State private var selectedItem: NavItem?

    init() {
        let settings = GameSettings.load()
        if let pinned = settings.pinnedGame, let match = navItems.first(where: { $0.title == pinned }) {
            _selectedItem = State(initialValue: match)
        } else if let last = settings.lastSelectedGame, let match = navItems.first(where: { $0.title == last }) {
            _selectedItem = State(initialValue: match)
        } else {
            _selectedItem = State(initialValue: navItems.first)
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // MARK: - 背景图
                    LauncherBgLayer(launcherState: launcherState, selectedItem: selectedItem, size: geo.size)
                    // MARK: - 内容区
                    HStack(spacing: 0) {
                        // 左侧导航栏
                        VStack(spacing: 16) {
                            ForEach(navItems) { item in
                                HoverGameButton(item: item, selectedItem: $selectedItem, setSelectedItem: setSelectedItem)
                            }
                            Spacer()
                        }
                        .padding(.vertical)
                        .frame(width: 180, height: geo.size.height)
                        .background(
                            VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                        )
                        .ignoresSafeArea() // 确保左侧导航栏充满整个屏幕高度

                        // 右侧游戏详情区域
                        if let selectedItem {
                            GameDetailView(item: selectedItem)
                                .ignoresSafeArea() // 右侧内容区充满剩余屏幕
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
                    .font(.headline)
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

extension ContentView {
    struct LauncherBgLayer: View {
        let launcherState: GameLauncherState
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
