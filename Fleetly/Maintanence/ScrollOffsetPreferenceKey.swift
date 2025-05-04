//
//  ScrollOffsetPreferenceKey.swift
//  Maintenance
//
//  Created by Gunjan Mishra on 25/04/25.
//


import SwiftUI

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
