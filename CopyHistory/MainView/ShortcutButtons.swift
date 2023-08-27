//
//  ShortcutButtons.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI

// TODO: Setting a lot of command shortcuts makes typing slow.
extension MainView {
    @ViewBuilder func Shortcuts() -> some View {
        Group {
            KeyboardCommandButtons(action: { isFocus = true }, keys: [.init(main: "f", sub: .command), .init(main: "/", sub: .command)])
            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, viewModel.copiedItems.endIndex > i {
                    viewModel.didSelected(viewModel.copiedItems[i])
                    focusedItemIndex = nil
                    NSApplication.shared.deactivate()
                }

            }, keys: [.init(main: .return, sub: .command)])

            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, viewModel.copiedItems.endIndex > i {
                    viewModel.delete(viewModel.copiedItems[i])
                }

            }, keys: [.init(main: "d", sub: .command.union(.shift))]).transaction { transaction in
                transaction.animation = nil
            }

            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, viewModel.copiedItems.endIndex > i {
                    viewModel.toggleFavorite(viewModel.copiedItems[i])
                }

            }, keys: [.init(main: "o", sub: .command)])

            KeyboardCommandButtons(action: {
                isExpanded.toggle()
            }, keys: [.init(main: "e", sub: .command)])

            KeyboardCommandButtons(action: {
                isShowingRTF.toggle()
            }, keys: [.init(main: "r", sub: .command)])

            KeyboardCommandButtons(action: {
                isShowingHTML.toggle()
            }, keys: [.init(main: "h", sub: .command)])
        }

        .opacity(0)
        .frame(width: .leastNonzeroMagnitude, height: .leastNonzeroMagnitude)
    }
}
