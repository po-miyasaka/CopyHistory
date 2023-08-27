//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI
import WebKit

struct MainView: View {
    
    enum OverlayViewType {
        case setting
        case feedback
    }
    
    @StateObject var viewModel: ViewModel = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    @State var overlayViewType: OverlayViewType? = nil
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
           OverlayContents()
        })
        .background(Color.mainViewBackground)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(ViewModel.build())
    }
}
