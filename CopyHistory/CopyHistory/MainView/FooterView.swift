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
            HStack(alignment: .firstTextBaseline) {
                Button(action: {
                    isSettingsPresented.toggle()
                    isFocus = !isSettingsPresented
                }, label: {
                    Image(systemName: isSettingsPresented ? "xmark" : "latch.2.case")
                })
                    .accentColor(.white)
                Spacer()

                if !isSettingsPresented {
                    VStack(alignment: .leading) {
                        Button(action: {
                            isAlertPresented = true
                        }, label: {
                            Image(systemName: "trash")
                        })
                    }
                }
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
