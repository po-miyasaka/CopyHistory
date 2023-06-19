//
//  ShortcutButtons.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI

extension MainView {
    @ViewBuilder func Shortcuts() -> some View {
        Group {
            KeyboardCommandButtons(action: { isFocus = true }, keys: [.init(main: "f", sub: .command), .init(main: "/", sub: .command)])
            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                    pasteboardService.didSelected(pasteboardService.copiedItems[i])
                    focusedItemIndex = nil
                    NSApplication.shared.deactivate()
                }

            }, keys: [.init(main: .return, sub: .command)])

            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                    pasteboardService.delete(pasteboardService.copiedItems[i])
                }

            }, keys: [.init(main: "d", sub: .command.union(.shift))]).transaction { transaction in
                transaction.animation = nil
            }

            KeyboardCommandButtons(action: {
                if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                    pasteboardService.toggleFavorite(pasteboardService.copiedItems[i])
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
