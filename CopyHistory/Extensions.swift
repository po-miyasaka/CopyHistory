//
//  Extensions.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import Foundation
import SwiftUI
extension Color {
    static var mainViewBackground = Color("mainViewBackground")
    static var mainAccent = Color("AccentColor")
}


extension View {
    /// Hides the view without changing the layout, and makes it ignore clicks while hidden.
    func visible(_ isVisible: Bool) -> some View {
        opacity(isVisible ? 1 : 0)
            .allowsHitTesting(isVisible)
    }
}
