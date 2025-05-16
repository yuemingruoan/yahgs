//
//  GameLauncherState.swift
//  yahgs
//
//  Created by Yuan Shine on 2025/5/11.
//

import Foundation

class GameLauncherState: ObservableObject {
    @Published var settings: LauncherSettings {
        didSet {
            settings.save()
        }
    }

    init() {
        self.settings = LauncherSettings.load()
    }

    func updatePinnedGame(to title: String) {
        settings.pinnedGame = title
        settings.save()
    }

    func updateLastSelectedGame(to title: String) {
        settings.lastSelectedGame = title
        settings.save()
    }

    func updateBackgroundPath(for title: String, path: String) {
        settings.customBackgroundPaths[title] = path
        settings.save()
    }

    func updateGamePath(for title: String, path: String) {
        settings.gamePaths[title] = path
        settings.save()
    }

    func refreshInstalledGameVersions() {
        for (game, path) in settings.gamePaths {
            let versionFile = URL(fileURLWithPath: path).appendingPathComponent("config.ini")
            if let version = try? String(contentsOf: versionFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                settings.gameVersions[game] = version
            }
        }
        settings.save()
    }

    func getDefaultPath(for title: String) -> String? {
        return settings.defaultPaths[title]
    }

    func updateGameVersion(for title: String, version: String) {
        settings.gameVersions[title] = version
        settings.save()
    }
}
