//
//  LauncherState.swift
//  yahgs
//
//  Created by Yuan Shine on 2025/5/11.
//

import Foundation

class LauncherState: ObservableObject {
    @Published var settings: LauncherSettings {
        didSet {
            repository.save(settings)
        }
    }

    private let repository: SettingsRepository

    init(repository: SettingsRepository = DefaultSettingsRepository()) {
        self.repository = repository
        self.settings = repository.load()
    }

    func updatePinnedGame(to title: String) {
        settings.pinnedGame = title
        repository.save(settings)
    }

    func updateLastSelectedGame(to title: String) {
        settings.lastSelectedGame = title
        repository.save(settings)
    }

    func updateBackgroundPath(for title: String, path: String) {
        settings.customBackgroundPaths[title] = path
        repository.save(settings)
    }

    func updateGamePath(for title: String, path: String) {
        settings.gamePaths[title] = path
        repository.save(settings)
    }

    func refreshInstalledGameVersions() {
        for (game, path) in settings.gamePaths {
            let versionFile = URL(fileURLWithPath: path).appendingPathComponent("config.ini")
            if let version = try? String(contentsOf: versionFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                settings.gameVersions[game] = version
            }
        }
        repository.save(settings)
    }

    func getDefaultPath(for title: String) -> String? {
        return settings.defaultPaths[title]
    }

    func updateGameVersion(for title: String, version: String) {
        settings.gameVersions[title] = version
        repository.save(settings)
    }

    func saveSettings() {
        repository.save(settings)
    }
}
