//
//  OverlayContents.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/25.
//

import Foundation
import SwiftUI

extension MainView {
    @ViewBuilder
    func OverlayContents() -> some View {
        if let overlayViewType {
            VStack(spacing: 8) {
                ZStack(alignment: .top) {
                    Color.mainViewBackground
                    switch overlayViewType {
                    case .setting:
                        SettingView(displayedCount: viewModel.displayedItemCountBinding, isShowingKeyboardShortcuts: $isShowingKeyboardShortcuts,
                                    isExpanded: $isExpanded,
                                    isShowingRTF: $isShowingRTF,
                                    isShowingHTML: $isShowingHTML,
                                    isShowingDate: $isShowingDate,
                                    overlayViewType: $overlayViewType
                        )
                    case .feedback:
                        FeedbackView(overlayViewType: $overlayViewType)
                    }
                }
                Footer().padding(.horizontal, 16).padding(.bottom, 16)
            }
        }
    }

}
