//
//  LauncherSettings.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import Foundation

public struct LauncherSettings: Codable {

    // Wine相关设置
    public var retinaEnabled: Bool
    public var dpiValue: Int
    public var mapCommandToControl: Bool
    public var winePath: String
    // 启动器界面设置
    public var pinnedGame: String?
    public var lastSelectedGame: String?
    public var customBackgroundPaths: [String: String]
    public var gameThemeColors: [String: String]
    // 游戏路径设置
    public var gamePaths: [String: String]
    public var defaultPaths: [String: String]
    // 游戏启动参数设置
    public var metalHUDEnabled: Bool
    public var acBypassDisabled: [String: Bool]
    // 版本信息
    public var wineVersion: String?
    public var dxmtVersion: String?
    public var gameVersions: [String: String]
    // 用户偏好设置
    public var preferredLanguage: String?
    public var autoCheckUpdate: Bool
    public var hasSeenWelcome: Bool


    public init(
        retinaEnabled: Bool = false,
        dpiValue: Int = 192,
        mapCommandToControl: Bool = false,
        winePath: String,
        pinnedGame: String? = nil,
        lastSelectedGame: String? = nil,
        customBackgroundPaths: [String: String] = [:],
        gameThemeColors: [String: String] = [:],
        gamePaths: [String: String] = [:],
        defaultPaths: [String: String] = [:],
        metalHUDEnabled: Bool = false,
        acBypassDisabled: [String: Bool] = [:],
        wineVersion: String?,
        dxmtVersion: String?,
        gameVersions: [String: String] = [:],
        preferredLanguage: String?,
        autoCheckUpdate: Bool,
        hasSeenWelcome: Bool
    ) {
        self.retinaEnabled = retinaEnabled
        self.dpiValue = dpiValue
        self.mapCommandToControl = mapCommandToControl
        self.winePath = winePath
        self.pinnedGame = pinnedGame
        self.lastSelectedGame = lastSelectedGame
        self.customBackgroundPaths = customBackgroundPaths
        self.gameThemeColors = gameThemeColors
        self.gamePaths = gamePaths
        self.defaultPaths = defaultPaths
        self.metalHUDEnabled = metalHUDEnabled
        self.acBypassDisabled = acBypassDisabled
        self.wineVersion = wineVersion
        self.dxmtVersion = dxmtVersion
        self.gameVersions = gameVersions
        self.preferredLanguage = preferredLanguage
        self.autoCheckUpdate = autoCheckUpdate
        self.hasSeenWelcome = hasSeenWelcome
    }
}

public extension LauncherSettings {
    static var `default`: LauncherSettings {
        LauncherSettings(
            retinaEnabled: false,
            dpiValue: 192,
            mapCommandToControl: false,
            winePath: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Yahgs/wine").path,
            pinnedGame: nil,
            lastSelectedGame: nil,
            customBackgroundPaths: [:],
            gameThemeColors: ["原神": "#64C4FA", "崩坏：星穹铁道": "#800080", "绝区零": "#FFA500"],
            gamePaths: [:],
            defaultPaths: [:],
            metalHUDEnabled: false,
            acBypassDisabled: ["原神": false, "崩坏：星穹铁道": false, "绝区零": false],
            wineVersion: nil,
            dxmtVersion: nil,
            gameVersions: [:],
            preferredLanguage: {
                let lang = Locale.current.language.languageCode?.identifier ?? "en"
                let supported = ["zh", "en", "ja", "fr"]
                return supported.contains(lang) ? lang : "en"
            }(),
            autoCheckUpdate: true,
            hasSeenWelcome: false
        )
    }
}
