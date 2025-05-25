//
//  WelcomeStepWelcome .swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/23.
//

import SwiftUI
import Foundation

struct WelcomeStepWelcome: View {
    var onContinue: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("欢迎使用 Yahgs")
                .font(.largeTitle)
                .bold()

            Text("一个专为游戏玩家设计的启动器")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                onContinue?()
            }) {
                Text("继续")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
