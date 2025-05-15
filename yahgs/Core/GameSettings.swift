//
//  GameSettings.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import Foundation

struct GameSettings: Codable {
    var preferredLanguage: String?
    var pinnedGame: String?
    var lastSelectedGame: String?
    
    var autoCheckUpdate: Bool
    var minimizeAfterLaunch: Bool
    var useCustomDPI: Bool
    var dpiValue: Int
    var mapCommandToControl: Bool

    var customBackgroundPaths: [String: String]
    var gamePaths: [String: String]
    var gameVersions: [String: String]

    static let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("gameSettings.json")
    }()

    static func load() -> GameSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return GameSettings(
                preferredLanguage: "简体中文",
                pinnedGame: nil,
                lastSelectedGame: nil,
                autoCheckUpdate: true,
                minimizeAfterLaunch: true,
                useCustomDPI: false,
                dpiValue: 100,
                mapCommandToControl: false,
                customBackgroundPaths: [:],
                gamePaths: [:],
                gameVersions: [:]
            )
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: Self.fileURL)
        }
    }
}
