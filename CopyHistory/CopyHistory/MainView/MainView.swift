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
    @State var focusedItemIndex: Int?
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @AppStorage("isExpanded") var isExpanded: Bool = true
    @AppStorage("isShowingRTF") var isShowingRTF: Bool = false
    @AppStorage("isShowingHTML") var isShowingHTML: Bool = false

    var changeWindowSize: (NSSize) -> Void

    init(changeWindowSize: @escaping (NSSize) -> Void) {
        self.changeWindowSize = changeWindowSize
    }

    var body: some View {
        Group {
            Header()
            Divider()
            ContentsView()
            Divider()
            Footer()
        }
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
                    secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {
                    })
                )
            }
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(changeWindowSize: { _ in }).environmentObject(PasteboardService.build())
    }
}

// wanna show big preview
// struct WebViewer: NSViewRepresentable {
//    let contentString: String
//    let content: Data
//
//    init? (content: Data?) {
//        guard let content = content, let contentString = String(data: content, encoding: .utf8) else { return nil }
//        self.content = content
//        self.contentString = contentString
//    }
//
//    func makeNSView(context _: Context) -> WKWebView {
//        let view =  WKWebView(frame: .zero)
//
//        let html = "<html contenteditable> <script>onbeforeunload = () => true</script> \(contentString)"
//        let filePath =  NSHomeDirectory() + "/Library/hoge.html"
//        FileManager.default.createFile(atPath: filePath, contents: html.data(using: .utf8))
//
//        let localurl = URL(fileURLWithPath: filePath )
//        let allowAccess = URL(fileURLWithPath: NSHomeDirectory())
//
//        view.loadFileURL(localurl, allowingReadAccessTo:  allowAccess)
//        return view
//    }
//
//    func updateNSView(_ view: WKWebView, context _: Context) {
//
//    }
//
//    typealias NSViewType = WKWebView
// }
