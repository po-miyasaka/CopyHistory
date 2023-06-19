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
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @AppStorage("isExpanded") var isExpanded: Bool = true
    @AppStorage("isShowingRTF") var isShowingRTF: Bool = false
    @AppStorage("isShowingHTML") var isShowingHTML: Bool = false
    
    var body: some View {
        VStack {
            Header().padding(.top, 16).padding(.horizontal, 8)
            Divider()
            ContentsView().padding(.horizontal)
            Divider()
            Footer().padding(.horizontal, 16).padding(.bottom, 16)
        }
        .overlay(content: {
           overlayContents()
        })
        
        .background(Color.mainViewBackground)
    }
    
    @ViewBuilder
    func overlayContents() -> some View {
        if let overlayViewType {
            VStack(spacing: 8) {
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
                        FeedbackView(overlayViewType: $overlayViewType)
                    }
                }
                Footer().padding(.horizontal, 16).padding(.bottom, 16)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(PasteboardService.build())
    }
}
