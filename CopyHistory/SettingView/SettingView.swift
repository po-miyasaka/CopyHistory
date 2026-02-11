//
//  SettingView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/08.
//

import StoreKit
import SwiftUI
struct SettingView: View {
    @Binding var displayedCount: String
    @Binding var isShowingKeyboardShortcuts: Bool

    @Binding var isExpanded: Bool
    @Binding var isShowingRTF: Bool
    @Binding var isShowingHTML: Bool
    @Binding var overlayViewType: MainView.OverlayViewType?

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Toggle("Show keyboard shortcuts", isOn: $isShowingKeyboardShortcuts)
                Divider()
                Toggle("Expand cells", isOn: $isExpanded)
                Divider()
                Toggle("Show items as RTF", isOn: $isShowingRTF)
                Divider()
                Toggle("Show items as HTML", isOn: $isShowingHTML)
                Divider()
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Max Displayed Items Count")
                    Text("This number doesn't effect on the amount of saved Items \nThe less, The faster").font(.caption)
                }
                Spacer()
                TextField("", text: $displayedCount).frame(width: 50)
            }

            Divider()

            CustomTransformEditorView()

            Divider()

            Spacer()
            Divider()

            Group {
                Button(action: {
                    if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2_shortcut_launch") {
                        NSWorkspace.shared.open(url)
                    }
                }, label: {
                    Text("A keyboard shortcut for launching (open another Website)")
                })

                Button(action: {
                    if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2") {
                        NSWorkspace.shared.open(url)
                    }
                }, label: {
                    Text("CopyHistory Website")
                })

                Button(action: {
                    SKStoreReviewController.requestReview()
                }, label: {
                    Text("Rate CopyHistory✨")
                })

                Button(action: {
                    overlayViewType = .feedback
                }, label: {
                    Text("Send a request / feedback")
                })
            }.buttonStyle(LinkButtonStyle())

            Divider()
            Text("Version: " + versionString)
                .padding(.bottom, 16)

        }.padding(8)

    }
}

struct SettingView_Previews: PreviewProvider {
    static var previews: some View {
        let binding: Binding<Bool> = .init(get: { true }, set: { _ in })

        let bindingOverlay: Binding<MainView.OverlayViewType?> = .init(get: { .setting }, set: { _ in })
        SettingView(displayedCount: .init(get: { "" }, set: { _ in }), isShowingKeyboardShortcuts: binding,
                    isExpanded: binding,
                    isShowingRTF: binding,
                    isShowingHTML: binding,
                    overlayViewType: bindingOverlay
        )
    }
}
