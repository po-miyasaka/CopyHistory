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
    @Binding var isShowingUpdatedDate: Bool
    @Binding var isShowingFileInfo: Bool
    @Binding var overlayViewType: MainView.OverlayViewType?
    @AppStorage(WindowWidth.key) private var windowWidth: Double = WindowWidth.defaultValue
    @AppStorage(WebTranslator.settingKey) private var webTranslator: String = WebTranslator.Service.deepL.rawValue
    @State private var languageInUse = AppLanguage.stored()
    @State private var chosenLanguage = AppLanguage.stored()
    @AppStorage(ViewModel.aiFilterLimitKey) private var aiFilterLimit: Int = ViewModel.aiFilterLimitDefault
    let onExportCSV: () -> Void
    let onImportCSV: () -> Void

    var body: some View {
        ScrollView {
            content
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                Toggle("Show updated date", isOn: $isShowingUpdatedDate)
                    .help("Display the date and time when each item was last updated")
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

            HStack {
                Text("Language")
                Spacer()
                Picker("", selection: $chosenLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
                .onChange(of: chosenLanguage) { $0.save() }
            }
            if chosenLanguage != languageInUse {
                HStack {
                    Text("Restart to apply the new language.").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button("Restart now", action: AppLanguage.relaunch)
                }
            }

            Divider()

            HStack {
                Text("Window width")
                Spacer()
                Slider(value: $windowWidth, in: WindowWidth.range, step: 50)
                    .frame(width: 160)
                Text("\(Int(windowWidth))").monospacedDigit().frame(width: 40, alignment: .trailing)
            }

            Divider()

            HStack {
                Text("Web translator")
                Spacer()
                Picker("", selection: $webTranslator) {
                    ForEach(WebTranslator.Service.allCases) { service in
                        Text(service.title).tag(service.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 210)
            }

            Divider()

            if AIFilterAvailability.isAvailable {
                Stepper(value: $aiFilterLimit, in: 10...500, step: 10) {
                    HStack {
                        Text("AI filter: max results")
                        Spacer()
                        Text("\(aiFilterLimit)").monospacedDigit()
                    }
                }

                Divider()
            }

            CustomTransformEditorView()

            Divider()

            HStack {
                Button("Export all data as CSV…", action: onExportCSV)
                    .help("Save every saved item (text, memo, favorite, dates) to a CSV file. Images and other binary data are not included.")
                Button("Import CSV…", action: onImportCSV)
                    .help("Add items from a CSV file exported by CopyHistory. Duplicates are skipped and everything is imported as plain text.")
            }

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

        }.padding(16)

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
                    isShowingUpdatedDate: binding,
                    isShowingFileInfo: binding,
                    overlayViewType: bindingOverlay,
                    onExportCSV: {},
                    onImportCSV: {}
        )
    }
}
