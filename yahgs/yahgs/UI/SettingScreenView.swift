import SwiftUI

enum SettingsTab: String, CaseIterable, Hashable {
    case general, gamePaths, others

    var label: String {
        switch self {
        case .general: return "通用设置"
        case .gamePaths: return "游戏设置"
        case .others: return "其他设置"
        }
    }
}

struct SettingsScreenView: View {
    @State private var selection: SettingsTab = .general
    @EnvironmentObject var launcherState: GameLauncherState

    var body: some View {
        HStack(spacing: 0) {
            // 左侧导航栏
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selection = tab
                        }) {
                            HStack {
                                Text(tab.label)
                                    .font(.title3)
                                    .foregroundColor(selection == tab ? .accentColor : .primary)
                                Spacer()
                            }
                            .padding(8)
                            .background(selection == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 8)

                Spacer() // 保证列表内容靠顶部，不居中
            }
            .frame(width: 160)

            Divider()

            // 右侧内容区域
            Group {
                switch selection {
                case .general:
                    GeneralSettingsView()
                case .gamePaths:
                    GamePathSettingsView()
                case .others:
                    OtherSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 840, minHeight: 540)
    }
}

// 以下是每个设置页面的占位符，可以在这些组件中填充具体内容
struct GeneralSettingsView: View {
    @State private var metalHUDEnabled = false
    @State private var retinaEnabled = false
    @State private var dpiSelected = false
    @State private var selectedDPI = "1600 DPI"
    @State private var mapCommandToControl = false
    @State private var selectedLanguage = "English"
    @State private var autoCheckForUpdates = true
    @State private var minimizeToTray = false
    
    // 添加背景图片选择
    @State private var selectedBackgroundImage: String = "default" // 默认选项

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 外观设置：背景图片选择
                VStack(alignment: .leading, spacing: 16) {
                    Text("外观设置")
                        .font(.title2)
                        .padding(.top, 20)

                    // 原神
                    HStack {
                        Text("原神背景")
                            .font(.body)
                        Spacer()
                        Button("自定义背景图片") {
                            // 添加选择图片逻辑
                        }
                        .font(.body)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(height: 40)
                        .overlay(
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal),
                            alignment: .leading
                        )

                    // 星穹铁道
                    HStack {
                        Text("星穹铁道背景")
                            .font(.body)
                        Spacer()
                        Button("自定义背景图片") {
                            // 添加选择图片逻辑
                        }
                        .font(.body)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(height: 40)
                        .overlay(
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal),
                            alignment: .leading
                        )

                    // 绝区零
                    HStack {
                        Text("绝区零背景")
                            .font(.body)
                        Spacer()
                        Button("自定义背景图片") {
                            // 添加选择图片逻辑
                        }
                        .font(.body)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(height: 40)
                        .overlay(
                            Text("未设置")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal),
                            alignment: .leading
                        )

                    HStack {
                        Spacer()
                        Button("恢复默认背景") {
                            // 恢复默认逻辑
                        }
                        .font(.body)
                        Spacer()
                    }
                    .padding(.top, 10)
                }

                Text("通用设置")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                Toggle("启用 Metal HUD", isOn: $metalHUDEnabled)
                    .font(.body)
                Toggle("启用 Retina 显示", isOn: $retinaEnabled)
                    .font(.body)
                
                Toggle("启用自定义 DPI 设置", isOn: $dpiSelected)
                    .font(.body)
                if dpiSelected {
                    VStack(alignment: .leading) {
                        Text("DPI 设置")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Picker("选择 DPI", selection: $selectedDPI) {
                            Text("800 DPI").font(.body).tag("800 DPI")
                            Text("1600 DPI").font(.body).tag("1600 DPI")
                            Text("3200 DPI").font(.body).tag("3200 DPI")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }

                Toggle("映射左侧 Command 键为 Control 键", isOn: $mapCommandToControl)
                    .font(.body)

                Divider()

                Toggle("启动后自动检查更新", isOn: $autoCheckForUpdates)
                    .font(.body)
                Toggle("启动时最小化至托盘", isOn: $minimizeToTray)
                    .font(.body)

                Divider()

                VStack(alignment: .leading) {
                    Text("Language / 语言设置")
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                    Picker("", selection: $selectedLanguage) {
                        Text("English").font(.body).tag("English")
                        Text("中文").font(.body).tag("中文")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Divider()

                Spacer()
            }
            .padding()
        }
    }
}

struct GamePathSettingsView: View {
    @EnvironmentObject var launcherState: GameLauncherState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("游戏设置")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(["原神", "星穹铁道", "绝区零"], id: \.self) { game in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(game)
                                    .font(.body)
                                Spacer()
                                Button("选择...") {
                                    // 路径选择逻辑
                                }
                                .font(.body)
                            }
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(height: 40)
                                .overlay(
                                    Text(launcherState.gamePaths[game] ?? "未设置")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal),
                                    alignment: .leading
                                )
                        }
                    }
                }
                
                Divider()

                Text("游戏内截图")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(["原神", "星穹铁道", "绝区零"], id: \.self) { game in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(game)
                                    .font(.body)
                                Spacer()
                                Button("打开文件夹") {
                                    // 打开截图文件夹逻辑
                                }
                                .font(.body)
                            }
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(height: 40)
                                .overlay(
                                    Text("未设置")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal),
                                    alignment: .leading
                                )
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct OtherSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("其他设置")
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                Toggle("启用设置1", isOn: .constant(false))
                    .font(.body)
                Toggle("启用设置2", isOn: .constant(false))
                    .font(.body)

                Spacer()
            }
            .padding()
        }
    }
}
