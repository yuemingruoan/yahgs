//
//  DownloadState.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import Foundation

public enum DownloadState: String, Codable, CaseIterable {
    case idle
    case downloading
    case paused
    case completed
    case failed
    case waiting
}
