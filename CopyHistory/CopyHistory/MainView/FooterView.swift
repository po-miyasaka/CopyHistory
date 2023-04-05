//
//  FooterView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import StoreKit
import SwiftUI

extension MainView {
    @ViewBuilder
    func Footer() -> some View {
        Group {
            HStack {
                Menu {
                    MenuItems(contents: [
                        .init(text: isShowingKeyboardShortcuts ? "Hide keyboard shortcuts" : "Show keyboard shortcuts", action: {
                            isShowingKeyboardShortcuts.toggle()
                        }),

                        .init(text: isShowingKeyboardShortcuts ? "Hide keyboard shortcuts" : "Show keyboard shortcuts", action: {
                            isShowingKeyboardShortcuts.toggle()
                        }),
                        .init(text: isExpanded ? "Minify cells" : "Expand cells", action: {
                            isExpanded.toggle()
                        }),
                        .init(text: isShowingRTF ? "Stop Showing as RTF" : "Show as RTF (slow)", action: {
                            isShowingRTF.toggle()
                        }),
                        .init(text: isShowingHTML ? "Stop Showing as HTML" : "Show as HTML (slow)", action: {
                            isShowingKeyboardShortcuts.toggle()
                        }),
                        .init(text: pasteboardService.shouldShowAllSavedItems ? "Show 100 items maximum (faster)" : "Show all saved items (slower)", action: {
                            pasteboardService.shouldShowAllSavedItems.toggle()
                        }),
                        .init(text: "About launching with a keyboard shortcut (open the Website)", action: {
                            if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2_shortcut_launch") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                        .init(text: "About CopyHistory (open the Website)", action: {
                            if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                        .init(text: "Rate CopyHistory✨", action: {
                            SKStoreReviewController.requestReview()
                        }),

                    ])

                    Text(versionString)

                } label: {
                    Image(systemName: "latch.2.case")
                        .font(.title)
                }
                .frame(width: 50)
                .accentColor(.white)

                Spacer()
                Button(action: {
                    isAlertPresented = true
                }, label: {
                    Image(systemName: "trash")
                })
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            VStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }, label: {
                    Text("Quit CopyHistory")
                })
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
}

struct MenuItems: View {
    struct Content: Identifiable {
        var id: String { text }
        let text: String
        let action: () -> Void
    }

    let contents: [Content]
    var body: some View {
        ForEach(contents) { content in
            Button(action: {
                content.action()
            }, label: {
                Text(content.text)
            })
            Divider()
        }
    }
}
