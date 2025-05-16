//
//  LauncherSettings.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import Foundation

struct LauncherSettings: Codable {
    var preferredLanguage: String?
    var pinnedGame: String?
    var lastSelectedGame: String?
    
    var autoCheckUpdate: Bool
    var metalHUDEnabled: Bool
    var retinaEnabled: Bool
    var dpiValue: Int
    var mapCommandToControl: Bool
    var hasSeenWelcome: Bool

    var customBackgroundPaths: [String: String]
    var gameThemeColors: [String: String]
    var gamePaths: [String: String]
    var gameVersions: [String: String]
    var defaultPaths: [String: String]
    var acBypassDisabled: [String: Bool]

    static let fileURL: URL = {
        return URL(fileURLWithPath: "/Users/stevetan/Library/Containers/Yahgs/Data/gameSettings.json")
    }()

    static func load() -> LauncherSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(LauncherSettings.self, from: data) else {
            return LauncherSettings(
                preferredLanguage: "zh",
                pinnedGame: nil,
                lastSelectedGame: nil,
                autoCheckUpdate: true,
                metalHUDEnabled: false,
                retinaEnabled: false,
                dpiValue: 192,
                mapCommandToControl: false,
                hasSeenWelcome: false,
                customBackgroundPaths: [:],
                gameThemeColors: ["原神": "#64C4FA", "崩坏：星穹铁道": "#800080", "绝区零": "#FFA500"],
                gamePaths: [:],
                gameVersions: [:],
                defaultPaths: [:],
                acBypassDisabled: ["原神": false, "崩坏：星穹铁道": false, "绝区零": false]
            )
        }
        return settings
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            print("尝试保存到：\(Self.fileURL.path)") //  打印保存路径
            try? data.write(to: Self.fileURL)
        }
    }
}
