//
//  SettingScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/9.
//

import SwiftUI
import Foundation
import AppKit
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable, Hashable {
    case general, appearance, others

    var label: String {
        switch self {
        case .general: return "通用设置"
        case .others: return "启动设置"
        case .appearance: return "外观设置"
        }
    }
}

struct SettingScreenView: View {
    let onDismiss: () -> Void
    @State private var selection: SettingsTab = .general
    @EnvironmentObject var LauncherViewModel: LauncherViewModel

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .medium))
                        Text("返回")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    Spacer()
                }

                Divider()

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
                                            .font(.system(size: 15))
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

                        Spacer()
                    }
                    .frame(width: 160, height: 540)

                    Divider()

                    // 右侧内容区域
                    Group {
                        switch selection {
                        case .general:
                            GeneralSettingsView()
                        case .others:
                            OtherSettingsView()
                        case .appearance:
                            AppearanceSettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: 960, height: 540)
            .offset(y: 28)
            .environment(\.font, .custom("PingFang SC", size: 16))
        }
        .ignoresSafeArea()
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var LauncherViewModel: LauncherViewModel
    private let backgroundsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Yahgs/backgrounds")
    private let themeColors = ["cyan", "purple", "orange", "custom"]
    let defaultColors: [String: String] = [
        "原神": "#64C4FA",
        "崩坏：星穹铁道": "#800080",
        "绝区零": "#FFA500"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("自定义背景图片")
                    .font(.system(size: 15))
                    .bold()
                VStack(spacing: 8) {
                    ForEach(["原神", "崩坏：星穹铁道", "绝区零"], id: \.self) { game in
                        HStack(spacing: 8) {
                            Text(game)
                                .font(.system(size: 15))
                                .frame(width: 150, alignment: .leading)
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .frame(height: 40)
                                .overlay(
                                    HStack {
                                        if let path = LauncherViewModel.settings.customBackgroundPaths[game] {
                                            Text((path as NSString).lastPathComponent)
                                                .font(.system(size: 15))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                        } else {
                                            Text("未设置")
                                                .font(.system(size: 15))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal)
                                        }
                                        Spacer()
                                    },
                                    alignment: .leading
                                )
                            Button("选择图片") {
                                chooseBackgroundImage(for: game)
                            }
                            .font(.system(size: 15))
                        }
                    }
                }

                Divider()

                Text("自定义主题色")
                    .font(.system(size: 15))
                    .bold()
                VStack(spacing: 8) {
                    ForEach(["原神", "崩坏：星穹铁道", "绝区零"], id: \.self) { game in
                        HStack(spacing: 8) {
                            Text(game)
                                .font(.system(size: 15))
                                .frame(width: 150, alignment: .leading)
                            ColorPicker("", selection: Binding(
                                get: {
                                    color(from: LauncherViewModel.settings.gameThemeColors[game] ?? defaultColors[game] ?? "#64C4FA")
                                },
                                set: {
                                    LauncherViewModel.settings.gameThemeColors[game] = hexString(from: $0)
                                }
                            ))
                            .labelsHidden()
                            .frame(width: 200)
                            Spacer()
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("恢复默认背景") {
                        for game in ["原神", "崩坏：星穹铁道", "绝区零"] {
                            LauncherViewModel.settings.customBackgroundPaths[game] = nil
                        }
                    }
                    .font(.system(size: 15))
                    Spacer()
                }
                .padding(.top, 10)

                HStack {
                    Spacer()
                    Button("恢复默认主题色") {
                        LauncherViewModel.settings.gameThemeColors = [
                            "原神": defaultColors["原神"]!,
                            "崩坏：星穹铁道": defaultColors["崩坏：星穹铁道"]!,
                            "绝区零": defaultColors["绝区零"]!
                        ]
                    }
                    .font(.system(size: 15))
                    .padding(.top, 5)
                    Spacer()
                }
            }
            .padding()
        }
    }

    private func chooseBackgroundImage(for game: String) {
        let panel = NSOpenPanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.jpeg, .png]
        } else {
            panel.allowedFileTypes = ["jpg", "jpeg", "png"]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.prompt = "选择图片"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                let gameBackgroundFolder = backgroundsPath.appendingPathComponent(game)
                if !FileManager.default.fileExists(atPath: gameBackgroundFolder.path) {
                    try? FileManager.default.createDirectory(at: gameBackgroundFolder, withIntermediateDirectories: true)
                }
                let destinationURL = gameBackgroundFolder.appendingPathComponent(url.lastPathComponent)
                try? FileManager.default.copyItem(at: url, to: destinationURL)
                LauncherViewModel.updateBackgroundPath(for: game, path: destinationURL.path)
            }
        }
    }

    private func hexString(from color: Color) -> String {
        let uiColor = NSColor(color)
        guard let rgbColor = uiColor.usingColorSpace(.deviceRGB) else {
            return "#FFFFFF"
        }
        let red = Int(round(rgbColor.redComponent * 255))
        let green = Int(round(rgbColor.greenComponent * 255))
        let blue = Int(round(rgbColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private func color(from hex: String) -> Color {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        if hexString.count != 6 {
            return Color.gray
        }
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var LauncherViewModel: LauncherViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("显示设置")
                        .font(.system(size: 15))
                        .bold()

                    HStack {
                        Text("启用 Metal HUD")
                            .font(.system(size: 15))
                        Spacer()
                        Toggle("", isOn: $LauncherViewModel.settings.metalHUDEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .frame(width: 50)
                    }

                    HStack {
                        Text("启用 Retina 显示")
                            .font(.system(size: 15))
                        Spacer()
                        Toggle("", isOn: $LauncherViewModel.settings.retinaEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .frame(width: 50)
                    }

                    HStack {
                        Text("DPI 设置")
                            .font(.system(size: 15))
                        Spacer()
                        Picker("选择 DPI", selection: $LauncherViewModel.settings.dpiValue) {
                            Text("96 DPI").tag(96)
                            Text("144 DPI").tag(144)
                            Text("192 DPI").tag(192)
                            Text("240 DPI").tag(240)
                            Text("288 DPI").tag(288)
                        }
                        .font(.system(size: 15))
                        .labelsHidden()
                        .frame(width: 200)
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                Divider()

                Group {
                    Text("控制设置")
                        .font(.system(size: 15))
                        .bold()

                    HStack {
                        Text("映射左侧 Command 键为 Control 键")
                            .font(.system(size: 15))
                        Spacer()
                        Toggle("", isOn: $LauncherViewModel.settings.mapCommandToControl)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .frame(width: 50)
                    }
                }

                Divider()

                Group {
                    HStack {
                        Text("语言设置 Language")
                            .font(.system(size: 15))
                        Spacer()
                        Picker("选择语言", selection: Binding(
                            get: { LauncherViewModel.settings.preferredLanguage ?? "en" },
                            set: { LauncherViewModel.settings.preferredLanguage = $0 }
                        )) {
                            Text("中文").tag("zh")
                            Text("日本語").tag("ja")
                            Text("English").tag("en")
                            Text("Français").tag("fr")
                        }
                        .font(.system(size: 15))
                        .labelsHidden()
                        .frame(width: 200)
                        .pickerStyle(MenuPickerStyle())
                    }

                    HStack {
                        Text("启动后自动检查更新")
                            .font(.system(size: 15))
                        Spacer()
                        Toggle("", isOn: $LauncherViewModel.settings.autoCheckUpdate)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .frame(width: 50)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct OtherSettingsView: View {
    @EnvironmentObject var LauncherViewModel: LauncherViewModel
    let games = ["原神", "崩坏：星穹铁道", "绝区零"]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("关闭 AC 补丁")
                    .font(.system(size: 15))
                    .bold()
                Text("启用此选项将禁用游戏的反作弊。这可能影响游戏安全检测，甚至存在封号风险。")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(games, id: \.self) { game in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(game)
                                .font(.system(size: 15))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { LauncherViewModel.settings.acBypassDisabled[game] ?? false },
                                set: { LauncherViewModel.settings.acBypassDisabled[game] = $0 }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .frame(width: 50)
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}
