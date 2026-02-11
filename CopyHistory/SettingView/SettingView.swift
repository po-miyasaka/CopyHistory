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
    @Binding var isShowingDate: Bool
    @Binding var isShowingFileInfo: Bool
    @Binding var overlayViewType: MainView.OverlayViewType?

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                Toggle("Show keyboard shortcuts", isOn: $isShowingKeyboardShortcuts)
                    .help("Show shortcut key hints on the main screen")
                Divider()
                Toggle("Expand cells", isOn: $isExpanded)
                    .help("Show clipboard content in multiple lines instead of a single line")
                Divider()
                Toggle("Show items as RTF", isOn: $isShowingRTF)
                    .help("Display Rich Text Format content with its original styling")
                Divider()
                Toggle("Show items as HTML", isOn: $isShowingHTML)
                    .help("Display HTML content with its original styling")
                Divider()
                Toggle("Show saved date", isOn: $isShowingDate)
                    .help("Display the date and time when each item was saved")
                Divider()
                Toggle("Show file type and size", isOn: $isShowingFileInfo)
                    .help("Display the content type (e.g. plain-text, image) and data size for each item")
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
            Text("Version: \(versionString)")
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
                    isShowingDate: binding,
                    isShowingFileInfo: binding,
                    overlayViewType: bindingOverlay
        )
    }
}
