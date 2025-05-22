//
//  DxmtService.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/21.
//

import Foundation

public class DxmtService {
    private let dxmtInitializer: DxmtInitializer

    public init(repository: SettingsRepository = DefaultSettingsRepository()) {
        self.dxmtInitializer = DxmtInitializer(repository: repository)
    }

    public func setupDxmt(from url: URL) throws {
        try dxmtInitializer.initialize(from: url)
        // 这里可以添加调用保存版本的方法，比如：
        // dxmtInitializer.saveInstalledVersion("v0.51")
    }
}
