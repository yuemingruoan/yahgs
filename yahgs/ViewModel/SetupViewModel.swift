//
//  SetupViewModel.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class SetupViewModel: ObservableObject {
    // 下载部分 ViewModel
    @Published var downloadVM = DownloadViewModel()

    // 操作部分 ViewModel
    @Published var operationVM = OperationViewModel()

    // 新增初始化状态变量
    @Published var initState: Step = .idle

    // 代理绑定：允许 View 双向绑定下载进度，但不允许外部写入
    var downloadProgressBinding: Binding<Double> {
        Binding(
            get: { self.downloadVM.progress },
            set: { _ in
                // 不允许外部修改进度，空实现
            }
        )
    }

    // 代理绑定：允许 View 双向绑定操作进度，但不允许外部写入
    var operationProgressBinding: Binding<Double> {
        Binding(
            get: { self.operationVM.progress },
            set: { _ in
                // 不允许外部修改进度，空实现
            }
        )
    }

    // 当前阶段描述
    @Published var currentStep: Step = .idle

    // 错误信息
    @Published var errorMessage: String? = nil

    enum Step {
        case idle
        case downloading
        case operating
        case completed
        case failed
    }

    // 任务组件
    let component: DownloadComponent

    // 下载目标路径
    let downloadDestination: URL

    // Combine 订阅集合
    private var cancellables = Set<AnyCancellable>()

    init(component: DownloadComponent, downloadDestination: URL) {
        self.component = component
        self.downloadDestination = downloadDestination

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
                    // 你可根据需求处理暂停和等待状态
                    break
                }
            }
            .store(in: &cancellables)

        // 修改为监听 initState
        $initState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                switch state {
                case .idle:
                    break
                case .operating, .downloading:
                    self.currentStep = .operating
                case .completed:
                    self.currentStep = .completed
                case .failed:
                    self.currentStep = .failed
                    self.errorMessage = "任务失败"
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        errorMessage = nil
        currentStep = .idle
        downloadVM.startDownload(component: component, to: downloadDestination)
    }

    private func startOperation() {
        Task {
            do {
                // 这里写你的初始化具体操作，比如调用服务层方法
                // await operationService.initializeComponent(component)

                // 示例：假设有个 async 方法执行初始化
                try await performInitialization()

                // 操作完成，更新状态
                await MainActor.run {
                    initState = .completed
                }
            } catch {
                await MainActor.run {
                    initState = .failed
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func performInitialization() async throws {
        // 这里写具体初始化流程代码，比如解压、移动、配置等
        // 模拟异步操作示例：
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    @MainActor
    func reset() {
        downloadVM = DownloadViewModel()
        operationVM = OperationViewModel()
        currentStep = .idle
        errorMessage = nil
        cancellables.removeAll()
        setupBindings()
    }
}
