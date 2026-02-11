//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI
import WebKit
import Combine

struct MainView: View {

    enum OverlayViewType {
        case setting
        case feedback
    }

    @StateObject var viewModel: ViewModel = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    @State var overlayViewType: OverlayViewType?
    @State var focusedItemIndex: Int?
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @AppStorage("isExpanded") var isExpanded: Bool = true
    @AppStorage("isShowingRTF") var isShowingRTF: Bool = false
    @AppStorage("isShowingHTML") var isShowingHTML: Bool = false

    @State var itemAction: ItemAction?

    enum Action: Hashable {
        case delete
        case memoEdited(String)
        case select
        case favorite
        case transform(TransformAction)
    }

    struct ItemAction {
        let item: CopiedItem
        let action: Action
    }

    var body: some View {
        VStack {
            Header().padding(.top, 16).padding(.horizontal, 8)
            Divider()
            ContentsView()
            Divider()
            Footer().padding(.horizontal, 16).padding(.bottom, 16)
        }
        .onReceive(Just(itemAction)) { actionItem in
            guard let actionItem else {
                return
            }

            switch actionItem.action {
            case .delete:
                viewModel.delete(actionItem.item)
            case .memoEdited(let memo):
                viewModel.saveMemo(actionItem.item, memo: memo)
            case .select:
                focusedItemIndex = nil
                viewModel.didSelected(actionItem.item)
                NSApplication.shared.deactivate()
            case .transform(let transformAction):
                focusedItemIndex = nil
                viewModel.didSelectWithTransform(actionItem.item, transform: transformAction)
                NSApplication.shared.deactivate()
            case .favorite:
                viewModel.toggleFavorite(actionItem.item)
            }
            self.itemAction = nil
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
