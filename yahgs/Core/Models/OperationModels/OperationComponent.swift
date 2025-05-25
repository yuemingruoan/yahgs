//
//  OperationComponent.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import Foundation

public enum OperationComponent: String, Codable, CaseIterable {
    case extract
    case moveFiles
    case configure
    case cleanup
}
