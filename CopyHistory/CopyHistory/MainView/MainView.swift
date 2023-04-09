//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI
import WebKit

struct MainView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    @State var isSettingsPresented: Bool = false
    @State var focusedItemIndex: Int?
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @AppStorage("isExpanded") var isExpanded: Bool = true
    @AppStorage("isShowingRTF") var isShowingRTF: Bool = false
    @AppStorage("isShowingHTML") var isShowingHTML: Bool = false

    var body: some View {
        Group {
            Header()
            Divider()
            ContentsView()
            Divider()
            Footer()
        }
        .overlay(content: {
            if isSettingsPresented {
                VStack {
                    ZStack(alignment: .top) {
                        Color.mainViewBackground
                        SettingView(displayedCount: pasteboardService.displayedItemCountBinding, isShowingKeyboardShortcuts: $isShowingKeyboardShortcuts,
                                    isExpanded: $isExpanded,
                                    isShowingRTF: $isShowingRTF,
                                    isShowingHTML: $isShowingHTML)
                    }
                    .padding(8)
                    Footer()
                }
            }
        })

        .background(Color.mainViewBackground)
        .alert(
            isPresented: $isAlertPresented,
            content: {
                Alert(
                    title: Text("Deleting all history except for favorited items"),
                    primaryButton: Alert.Button.destructive(
                        Text("Delete"),
                        action: {
                            pasteboardService.clearAll()
                        }
                    ),
                    secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
                )
            }
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(PasteboardService.build())
    }
}
