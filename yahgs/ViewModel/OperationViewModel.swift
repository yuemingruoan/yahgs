//
//  OperationViewModel.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//

import Foundation
import Combine

public class OperationViewModel: ObservableObject {
    @Published public private(set) var phaseDescription: String = "准备中..."
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var state: OperationState = .idle
    @Published public private(set) var errorMessage: String? = nil

    @MainActor
    private func updatePhase(_ description: String, progress: Double) async {
        self.phaseDescription = description
        self.progress = progress
        self.state = .executing
    }

    /// 重置状态
    public func reset() {
        phaseDescription = "准备中..."
        progress = 0.0
        state = .idle
        errorMessage = nil
    }
}
