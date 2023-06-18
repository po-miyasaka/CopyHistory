//
//  HeaderView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI

extension MainView {
    @ViewBuilder
    func Header() -> some View {
        Group {
            HStack(alignment: .center, spacing: 10) {
                TextField(isShowingKeyboardShortcuts ? "Search: ⌘ + f" : "Search", text: $pasteboardService.searchText)

                    .focused($isFocus)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: pasteboardService.searchText, perform: { _ in
                        focusedItemIndex = nil
                        withAnimation {
                            pasteboardService.search()
                        }
                    })
                    .foregroundColor(.primary)
                Text("\(pasteboardService.copiedItems.count)")
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }.padding()

            HStack(alignment: .bottom) {
                if isShowingKeyboardShortcuts {
                    HStack {
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("Up:")
                            Text("Down:")
                            Text("Select:")
                            Text("Delete:")
                            Text("Star:")
                            Text("Write a memo:")
                            Text(isExpanded ? "Minify cells:" : "Expand cells:")
                            Text(isShowingRTF ? "Stop Showing as RTF:" : "Show as RTF (slow):")
                            Text(isShowingHTML ? "Stop Showing as HTML:" : "Show as HTML (slow):")
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("⌘ + ↑ or k")
                            Text("⌘ + ↓ or j")
                            Text("⌘ + ↩")
                            Text("⌘ + ⇧ + d")
                            Text("⌘ + o")
                            Text("⌘ + i")
                            Text("⌘ + e")
                            Text("⌘ + r")
                            Text("⌘ + h")
                        }
                    }.font(.caption)
                        .foregroundColor(Color.gray)
                        .padding(.bottom, 1)
                }

                Spacer()

                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            pasteboardService.filterMemoed()
                        }

                    }, label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(pasteboardService.isShowingOnlyMemoed ? Color.mainAccent : Color.primary)
                    })
                        .keyboardShortcut("p", modifiers: .command)

                    if isShowingKeyboardShortcuts {
                        Text("⌘ + p").font(.caption).foregroundColor(.gray).padding(.top, 2)
                    }
                }

                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            pasteboardService.filterFavorited()
                        }

                    }, label: {
                        Image(systemName: pasteboardService.isShowingOnlyFavorite ? "star.fill" : "star")
                            .foregroundColor(pasteboardService.isShowingOnlyFavorite ? Color.mainAccent : Color.primary)
                    })
                        .keyboardShortcut("s", modifiers: .command)

                    if isShowingKeyboardShortcuts {
                        Text("⌘ + s").font(.caption).foregroundColor(.gray).padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
