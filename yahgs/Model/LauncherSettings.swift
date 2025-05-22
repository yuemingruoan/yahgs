//
//  LauncherSettings.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import Foundation

public struct LauncherSettings: Codable {
    public var preferredLanguage: String?
    public var pinnedGame: String?
    public var lastSelectedGame: String?
    public var wineVersion: String?
    public var dxmtVersion: String?

    public var autoCheckUpdate: Bool
    public var metalHUDEnabled: Bool
    public var retinaEnabled: Bool
    public var dpiValue: Int
    public var mapCommandToControl: Bool
    public var hasSeenWelcome: Bool

    public var customBackgroundPaths: [String: String]
    public var gameThemeColors: [String: String]
    public var gamePaths: [String: String]
    public var gameVersions: [String: String]
    public var defaultPaths: [String: String]
    public var acBypassDisabled: [String: Bool]

    public var winePath: String

    public init(
        preferredLanguage: String?,
        pinnedGame: String?,
        lastSelectedGame: String?,
        wineVersion: String?,
        dxmtVersion: String?,
        autoCheckUpdate: Bool,
        metalHUDEnabled: Bool,
        retinaEnabled: Bool,
        dpiValue: Int,
        mapCommandToControl: Bool,
        hasSeenWelcome: Bool,
        customBackgroundPaths: [String: String],
        gameThemeColors: [String: String],
        gamePaths: [String: String],
        gameVersions: [String: String],
        defaultPaths: [String: String],
        acBypassDisabled: [String: Bool],
        winePath: String
    ) {
        self.preferredLanguage = preferredLanguage
        self.pinnedGame = pinnedGame
        self.lastSelectedGame = lastSelectedGame
        self.wineVersion = wineVersion
        self.dxmtVersion = dxmtVersion
        self.autoCheckUpdate = autoCheckUpdate
        self.metalHUDEnabled = metalHUDEnabled
        self.retinaEnabled = retinaEnabled
        self.dpiValue = dpiValue
        self.mapCommandToControl = mapCommandToControl
        self.hasSeenWelcome = hasSeenWelcome
        self.customBackgroundPaths = customBackgroundPaths
        self.gameThemeColors = gameThemeColors
        self.gamePaths = gamePaths
        self.gameVersions = gameVersions
        self.defaultPaths = defaultPaths
        self.acBypassDisabled = acBypassDisabled
        self.winePath = winePath
    }
}

public extension LauncherSettings {
    static var `default`: LauncherSettings {
        LauncherSettings(
            preferredLanguage: {
                let lang = Locale.current.language.languageCode?.identifier ?? "en"
                let supported = ["zh", "en", "ja", "fr"]
                return supported.contains(lang) ? lang : "en"
            }(),
            pinnedGame: nil,
            lastSelectedGame: nil,
            wineVersion: nil,
            dxmtVersion: nil,
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
            acBypassDisabled: ["原神": false, "崩坏：星穹铁道": false, "绝区零": false],
            winePath: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Yahgs/wine").path
        )
    }
}
