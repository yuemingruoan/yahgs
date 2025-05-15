//
//  SettingScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/9.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

enum SettingsTab: String, CaseIterable, Hashable {
    case general, appearance, others

    var label: String {
        switch self {
        case .general: return "通用设置"
        case .others: return "其他设置"
        case .appearance: return "外观设置"
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
            .frame(width: 160, height:540)

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
           // .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 840, minHeight: 540)
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var launcherState: GameLauncherState
    private let backgroundsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Yahgs/backgrounds")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("外观设置")
                    .font(.title2)
                    .padding(.top, 20)

                ForEach(["原神", "星穹铁道", "绝区零"], id: \.self) { game in
                    HStack {
                        Text("\(game)背景")
                            .font(.body)
                        Spacer()
                        Button("自定义背景图片") {
                            chooseBackgroundImage(for: game)
                        }
                        .font(.body)
                    }
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .frame(height: 40)
                        .overlay(
                            HStack {
                                if let imagePath = launcherState.settings.customBackgroundPaths[game],
                                   let nsImage = NSImage(contentsOfFile: imagePath) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                } else {
                                    Text("未设置")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                }
                                Spacer()
                            },
                            alignment: .leading
                        )
                }

                HStack {
                    Spacer()
                    Button("恢复默认背景") {
                        for game in ["原神", "星穹铁道", "绝区零"] {
                            launcherState.settings.customBackgroundPaths[game] = nil
                        }
                    }
                    .font(.body)
                    Spacer()
                }
                .padding(.top, 10)
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
                launcherState.updateBackgroundPath(for: game, path: destinationURL.path)
            }
        }
    }
}

struct GeneralSettingsView: View {
    @State private var metalHUDEnabled = false
    @State private var retinaEnabled = false
    @State private var dpiSelected = false
    @State private var selectedDPI = "1600 DPI"
    @State private var mapCommandToControl = false
    @State private var selectedLanguage = "English"
    @State private var autoCheckForUpdates = true
    @State private var minimizeToTray = false
    
    @EnvironmentObject var launcherState: GameLauncherState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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
