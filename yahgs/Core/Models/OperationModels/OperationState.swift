//
//  OperationState.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import Foundation

public enum OperationState: String, Codable, CaseIterable {
    case idle
    case executing
    case completed
    case failed
}
