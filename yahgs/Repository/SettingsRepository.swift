//
//  SettingsRepository.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public protocol SettingsRepository {
    func load() -> LauncherSettings
    func save(_ settings: LauncherSettings)
}
