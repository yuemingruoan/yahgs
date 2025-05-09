import SwiftUI
struct ContentView: View {
    var body: some View {
        // 使用GeometryReader获取父视图尺寸
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 左侧导航栏（固定宽度）
                NavigationView {
                    List {
                        NavigationLink(destination: EmptyView()) {
                            Label("Genshin Impact", systemImage: "plus.app")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .cornerRadius(6)
                        }
                        
                        NavigationLink(destination: EmptyView()) {
                            Label("Honkai Star Rail", systemImage: "star")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .cornerRadius(6)
                        }
                        
                        NavigationLink(destination: EmptyView()) {
                            Label("Zenless Zone Zero", systemImage: "map")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .cornerRadius(6)
                        }
                        
                        NavigationLink(destination: EmptyView()) {
                            Label("Settings", systemImage: "gearshape")
                                .foregroundColor(.primary)
                                .padding(.horizontal, 8)
                                .cornerRadius(6)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .frame(width: 220) // 固定左侧宽度
                    .scrollContentBackground(.hidden)
                }
                
                // 右侧区域（自动填充剩余空间）
                Rectangle()
                    .fill(Color.clear)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            // 确保HStack尺寸随父视图变化
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}
