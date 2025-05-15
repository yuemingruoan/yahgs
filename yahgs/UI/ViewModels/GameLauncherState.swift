//
//  GameLauncherState.swift
//  yahgs
//
//  Created by Yuan Shine on 2025/5/11.
//

import Foundation

class GameLauncherState: ObservableObject {
    @Published var settings: GameSettings {
        didSet {
            settings.save()
        }
    }

    init() {
        self.settings = GameSettings.load()
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
}
