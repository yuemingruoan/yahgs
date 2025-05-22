//
//  DefaultSettingsRepository.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public class DefaultSettingsRepository: SettingsRepository {
    private let fileURL: URL = {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Yahgs")
            .appendingPathComponent("gameSettings.json")
    }()

    public init() {} // 添加公开初始化器

    public func load() -> LauncherSettings {
        guard let data = try? Data(contentsOf: fileURL),
              let settings = try? JSONDecoder().decode(LauncherSettings.self, from: data) else {
            return LauncherSettings.default
        }
        return settings
    }

    public func save(_ settings: LauncherSettings) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(settings) {
            print("保存到：\(fileURL.path)")
            try? data.write(to: fileURL)
        }
    }
}
