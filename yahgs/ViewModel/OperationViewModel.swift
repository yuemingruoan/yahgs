//
//  OperationViewModel.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
public class OperationViewModel: ObservableObject {
    @Published public private(set) var phaseDescription: String = "准备中..."
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var state: OperationState = .idle
    @Published public private(set) var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    @MainActor
    private var downloadVM: DownloadViewModel

    public var downloadProgressBinding: Binding<Double> {
        Binding(
            get: { self.downloadVM.progress },
            set: { _ in }
        )
    }

    public var operationProgressBinding: Binding<Double> {
        Binding(
            get: { self.progress },
            set: { _ in }
        )
    }

    public enum Step {
        case idle
        case downloading
        case operating
        case completed
        case failed
    }

    @Published public private(set) var currentStep: Step = .idle

    private let component: DownloadComponent
    private let downloadDestination: URL

    private let wineService = WineService(downloadService: DownloadService())
    private let dxmtService = DxmtService(downloadService: DownloadService())

    public init(component: DownloadComponent, downloadDestination: URL, downloadVM: DownloadViewModel) {
        self.component = component
        self.downloadDestination = downloadDestination
        self.downloadVM = downloadVM
        setupBindings()
    }

    private func setupBindings() {
        downloadVM.$downloadState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .idle:
                    self.currentStep = .idle
                case .downloading:
                    self.currentStep = .downloading
                case .completed:
                    self.currentStep = .operating
                    self.startOperation()
                case .failed:
                    self.currentStep = .failed
                    self.errorMessage = "下载失败"
                case .paused, .waiting:
                    break
                }
            }
            .store(in: &cancellables)
    }

    public func start() async {
        errorMessage = nil
        currentStep = .idle
        do {
            try await downloadVM.startDownload(component: component, to: downloadDestination)
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .failed
        }
    }

    public func startOperation() {
        Task {
            do {
                try await performInitialization()
                await MainActor.run {
                    self.currentStep = .completed
                }
            } catch {
                await MainActor.run {
                    self.currentStep = .failed
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func performInitialization() async throws {
        switch component {
        case .wine:
            try await wineService.installWine(from: downloadDestination) { percent in
                DispatchQueue.main.async {
                    print("[OperationViewModel] 初始化进度（Wine）：\(percent)")
                    self.updateProgress(percent)
                }
            }
        case .dxmt:
            try await dxmtService.installDxmt(from: downloadDestination) { percent in
                DispatchQueue.main.async {
                    print("[OperationViewModel] 初始化进度（Dxmt）：\(percent)")
                    self.updateProgress(percent)
                }
            }
        }
    }

    @MainActor
    public func reset() {
        progress = 0.0
        currentStep = .idle
        errorMessage = nil
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        setupBindings()
    }

    @MainActor
    public func updateProgress(_ value: Double) {
        self.progress = value
    }
}
