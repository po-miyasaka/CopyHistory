//
//  SlowPasteboardReadBanner.swift
//  CopyHistory
//
//  Shown while a pasteboard read is taking unusually long, e.g. when macOS is still
//  fetching content from a Handoff device or a device simulator.
//

import SwiftUI

extension MainView {
    @ViewBuilder
    func SlowPasteboardReadBanner() -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("This is taking a while. Clipboard sharing with a Handoff device or a device simulator may be slow to respond.")
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption)
        .foregroundColor(.red)
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.isPasteboardReadSlow)
    }
}
