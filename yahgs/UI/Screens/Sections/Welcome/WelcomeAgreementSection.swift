//
//  WelcomeAgreementSection.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/16.
//



import SwiftUI

struct WelcomeAgreementSection: View {
    var welcomeTitle: some View {
        Text("欢迎与使用须知")
            .font(.largeTitle)
            .bold()
            .padding(.bottom, 8)
            .multilineTextAlignment(.center)
    }
    
    var welcomeTexts: some View {
        Group {
            Text("欢迎使用 YAHGS 启动器！")
                .font(.title)
                .multilineTextAlignment(.center)
            Text("""
\u{3000}\u{3000}本启动器由两位热爱《原神》的开发者联合打造，旨在学习 SwiftUI 技术，并为 macOS 用户提供便捷的游戏启动及管理工具。

\u{3000}\u{3000}鉴于《原神》《崩坏：星穹铁道》《绝区零》等游戏尚未推出官方 macOS 版本，YAHGS 启动器致力于通过轻量、简洁且功能完善的设计，支持多款游戏的启动、自定义启动器封面以及游戏下载与版本更新，帮助用户获得更优质的游戏体验。
""")
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .font(.title3)
    }
    
    var noticeTitle: some View {
        Text("使用须知：")
            .font(.title2)
            .padding(.top, 12)
            .multilineTextAlignment(.leading)
    }
    
    var redNotices: some View {
        Group {
            Text(" \u{3000}\u{3000}1. 用户在使用本软件时，须严格遵守《原神》《崩坏：星穹铁道》《绝区零》等游戏的官方相关规定和条款。")
                .foregroundColor(.red)
                .bold()
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
            Text(" \u{3000}\u{3000}2. 本软件不会收集用户的任何个人信息，所有相关数据均仅存储于用户本地设备，以保障用户隐私安全。")
                .foregroundColor(.red)
                .bold()
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
            Text(" \u{3000}\u{3000}3. 鉴于 macOS 平台非官方支持的特殊性质，使用本软件存在潜在封禁风险。开发者已尽充分告知义务，用户须自行承担由此产生的全部风险和后果。")
                .foregroundColor(.red)
                .bold()
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .font(.title3)
    }
    
    var normalNotices: some View {
        Group {
            Text(" \u{3000}\u{3000}4. 本软件不保证在所有运行环境中均能稳定运行，用户在使用过程中应妥善备份相关数据，避免因异常情况导致数据丢失。")
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
            Text(" \u{3000}\u{3000}5. 本软件仅供个人学习和使用，严禁用于任何商业用途。")
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
            Text(" \u{3000}\u{3000}6. 本软件版权归开发者所有，未经许可，禁止任何形式的复制、传播及商业利用。")
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
        }
        .font(.title3)
        .padding(.leading, 8)
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    welcomeTitle
                    welcomeTexts
                    noticeTitle
                    redNotices
                    normalNotices
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .frame(maxWidth: 640)
            }
            .scrollIndicators(.hidden)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
