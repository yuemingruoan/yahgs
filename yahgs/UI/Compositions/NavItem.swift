//
//  NavItem.swift
//  yahgs
//
//  Created by Steve Tan on 2025/5/15.
//

import SwiftUI

struct NavItem: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let icon: String
    let themeColor: Color
    let coverImage: String
    let version: String = "1.0.0"
}
