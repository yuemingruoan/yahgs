//
//  SplashScreenView.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/17.
//

import SwiftUI

// MARK: - 启动动画页
struct SplashScreenView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("YAHGS 正在启动...")
                .font(.largeTitle)
                .opacity(0.7)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.05))
    }
}
