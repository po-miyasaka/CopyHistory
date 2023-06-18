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
    @State var overlayViewType: OverlayViewType? = nil
    enum OverlayViewType {
        case setting
        case feedback
    }
    @State var focusedItemIndex: Int?
    @State var isThanksDialogPresented: Bool = false
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
            if let overlayViewType {
                VStack {
                    ZStack(alignment: .top) {
                        Color.mainViewBackground
                        switch overlayViewType {
                        case .setting:
                            SettingView(displayedCount: pasteboardService.displayedItemCountBinding, isShowingKeyboardShortcuts: $isShowingKeyboardShortcuts,
                                        isExpanded: $isExpanded,
                                        isShowingRTF: $isShowingRTF,
                                        isShowingHTML: $isShowingHTML,
                                        overlayViewType: $overlayViewType)
                        case .feedback:
                            FeedbackView(overlayViewType: $overlayViewType, isAlertPresented: $isThanksDialogPresented)
                        }
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
        .alert(
            isPresented: $isThanksDialogPresented,
            content: {
                Alert(title: Text("Thank you for your feedback!! \n We will put it into practice."), message: nil, dismissButton: Alert.Button.default(
                    Text("OK"),
                    action: {
                        overlayViewType = nil
                    }
                ))
            }
        )
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(PasteboardService.build())
    }
}
