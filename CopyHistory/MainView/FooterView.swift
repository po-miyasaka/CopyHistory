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
        VStack {
            HStack(alignment: .firstTextBaseline) {
                Button(action: {
                    overlayViewType = overlayViewType == nil ?  .setting : nil
                    isFocus = overlayViewType == nil
                }, label: {
                    Image(systemName: overlayViewType == nil ? "latch.2.case" : "xmark")
                })
                .accentColor(.white)
                Spacer()

                if overlayViewType == nil {
                    VStack(alignment: .leading) {
                        Button(action: {
                            isAlertPresented = true
                        }, label: {
                            Image(systemName: "trash")
                        })
                    }
                }
            }

            Button(action: {
                NSApplication.shared.terminate(nil)
            }, label: {
                Text("Quit CopyHistory")
            })

        }
        .alert(
            isPresented: $isAlertPresented,
            content: {
                Alert(
                    title: Text("Deleting all history except for favorited items"),
                    primaryButton: Alert.Button.destructive(
                        Text("Delete"),
                        action: {
                            viewModel.clearAll()
                        }
                    ),
                    secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
                )
            }
        )
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
