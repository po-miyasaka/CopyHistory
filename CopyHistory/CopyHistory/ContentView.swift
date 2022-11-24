//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import StoreKit
import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    @State var focusedItemIndex: Int?
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @AppStorage("isExpanded") var isExpanded: Bool = true
    @AppStorage("isShowingRTF") var isShowingRTF: Bool = false
    @AppStorage("isShowingHTML") var isShowingHTML: Bool = false

    let versionString: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "") (\(build ?? ""))"
    }()

    var body: some View {
        Group {
            Header()
            Divider()
            MainView()
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
                    secondaryButton: Alert.Button.cancel(Text("Cancel"), action: {})
                )
            }
        )
    }

    enum Direction {
        case up
        case down
    }

    func scroll(proxy: ScrollViewProxy, direction: Direction) {
        if pasteboardService.copiedItems.isEmpty {
            return
        }
        let _focusedItemIndex: Int
        switch direction {
        case .down:
            if let i = focusedItemIndex, pasteboardService.copiedItems.count - 1 > i {
                _focusedItemIndex = i + 1
            } else {
                _focusedItemIndex = 0
            }

        case .up:
            if let i = focusedItemIndex, i > 0 {
                _focusedItemIndex = i - 1
            } else {
                _focusedItemIndex = pasteboardService.copiedItems.count - 1
            }
        }
        focusedItemIndex = _focusedItemIndex
        proxy.scrollTo(pasteboardService.copiedItems[_focusedItemIndex].dataHash)
    }

    @ViewBuilder
    func Header() -> some View {
        Group {
            HStack(alignment: .center, spacing: 10) {
                TextField(isShowingKeyboardShortcuts ? "Search: ⌘ + f" : "Search", text: $pasteboardService.searchText)

                    .focused($isFocus)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: pasteboardService.searchText, perform: { _ in
                        focusedItemIndex = nil
                        withAnimation {
                            pasteboardService.search()
                        }
                    })
                    .foregroundColor(.primary)
                Text("\(pasteboardService.copiedItems.count)")
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }.padding()

            HStack(alignment: .bottom) {
                if isShowingKeyboardShortcuts {
                    HStack {
                        VStack(alignment: .trailing, spacing: 5) {
                            Text("Up:")
                            Text("Down:")
                            Text("Select:")
                            Text("Delete:")
                            Text("Star:")
                            Text(isExpanded ? "Minify cells:" : "Expand cells:")
                            Text(isShowingRTF ? "Stop Showing as RTF:" : "Show as RTF (slow):")
                            Text(isShowingHTML ? "Stop Showing as HTML:" : "Show as HTML (slow):")
                        }
                        VStack(alignment: .leading, spacing: 5) {
                            Text("⌘ + ↑ or k")
                            Text("⌘ + ↓ or j")
                            Text("⌘ + ↩")
                            Text("⌘ + ⇧ + d")
                            Text("⌘ + o")
                            Text("⌘ + e")
                            Text("⌘ + r")
                            Text("⌘ + a")
                        }
                    }.font(.caption)
                        .foregroundColor(Color.gray)
                        .padding(.bottom, 1)
                }

                Spacer()

                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            pasteboardService.favoriteFilterButtonDidTap()
                        }

                    }, label: {
                        Image(systemName: pasteboardService.isShowingOnlyFavorite ? "star.fill" : "star")
                            .foregroundColor(pasteboardService.isShowingOnlyFavorite ? Color.mainAccent : Color.primary)
                    })
                    .keyboardShortcut("s", modifiers: .command)

                    if isShowingKeyboardShortcuts {
                        Text("⌘ + s").font(.caption).foregroundColor(.secondary).padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    func MainView() -> some View {
        ScrollView {
            // there is a mysterious plain view at the top of the scrollview and it overlays this content. so this is put here
            Spacer()
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    // ・This doesn't make ScrollView + ForEach make additional padding, https://www.reddit.com/r/SwiftUI/comments/e607z3/swiftui_scrollview_foreach_padding_weird/
                    // ・Lazy improves performance the inclement search

                    ForEach(Array(zip(pasteboardService.copiedItems.indices, pasteboardService.copiedItems)), id: \.1.dataHash) { index, item in

                        Row(item: item,
                            favorite: item.favorite,
                            didSelected: { item in
                                focusedItemIndex = nil
                                pasteboardService.didSelected(item)
                                NSApplication.shared.deactivate()
                            },
                            favoriteButtonDidTap: { item in pasteboardService.favoriteButtonDidTap(item) },
                            deleteButtonDidTap: { item in pasteboardService.deleteButtonDidTap(item) },
                            isFocused: index == focusedItemIndex,
                            isExpanded: $isExpanded,
                            isShowingRTF: $isShowingRTF,
                            isShowingHTML: $isShowingHTML)
                            .id(item.dataHash)
//                           Althoulgh this code enable selecting by hover, I commented it out because of not good UI Performances and experience.
//                            .onHover(perform: { hover in
//                                if hover {
//                                    focusedItemIndex = index
//                                }
//                            })
                    }
                }

                HStack {
                    KeyboardCommandButtons(action: { scroll(proxy: proxy, direction: .down) }, keys:
                        [.init(main: .downArrow, sub: .command), .init(main: "j", sub: .command)])

                    KeyboardCommandButtons(action: { scroll(proxy: proxy, direction: .up) }, keys:
                        [.init(main: .upArrow, sub: .command), .init(main: "k", sub: .command)])

                    KeyboardCommandButtons(action: { isFocus = true }, keys: [.init(main: "f", sub: .command), .init(main: "/", sub: .command)])
                    KeyboardCommandButtons(action: {
                        if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                            pasteboardService.didSelected(pasteboardService.copiedItems[i])
                            focusedItemIndex = nil
                            NSApplication.shared.deactivate()
                        }

                    }, keys: [.init(main: .return, sub: .command)])

                    KeyboardCommandButtons(action: {
                        if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                            pasteboardService.deleteButtonDidTap(pasteboardService.copiedItems[i])
                        }

                    }, keys: [.init(main: "d", sub: .command.union(.shift))]).transaction { transaction in
                        transaction.animation = nil
                    }

                    KeyboardCommandButtons(action: {
                        if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                            pasteboardService.favoriteButtonDidTap(pasteboardService.copiedItems[i])
                        }

                    }, keys: [.init(main: "o", sub: .command)])

                    KeyboardCommandButtons(action: {
                        isExpanded.toggle()
                    }, keys: [.init(main: "e", sub: .command)])

                    KeyboardCommandButtons(action: {
                        isShowingRTF.toggle()
                    }, keys: [.init(main: "r", sub: .command)])

                    KeyboardCommandButtons(action: {
                        isShowingHTML.toggle()
                    }, keys: [.init(main: "a", sub: .command)])
                }

                .opacity(0)
                .frame(width: .leastNonzeroMagnitude, height: .leastNonzeroMagnitude)
            }.padding(.horizontal)
        }
    }

    @ViewBuilder
    func Footer() -> some View {
        Group {
            HStack {
                Menu {
                    MenuItems(contents: [
                        .init(text: isShowingKeyboardShortcuts ? "Hide keyboard shortcuts" : "Show keyboard shortcuts", action: {
                            isShowingKeyboardShortcuts.toggle()
                        }),
                        .init(text: isExpanded ? "Minify cells" : "Expand cells", action: {
                            isExpanded.toggle()
                        }),
                        .init(text: isShowingRTF ? "Stop Showing as RTF" : "Show as RTF (slow)", action: {
                            isShowingRTF.toggle()
                        }),
                        .init(text: isShowingHTML ? "Stop Showing as HTML" : "Show as HTML (slow)", action: {
                            isShowingKeyboardShortcuts.toggle()
                        }),
                        .init(text: "About launching with a keyboard shortcut (open the Website)", action: {
                            if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2_shortcut_launch") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                        .init(text: "About CopyHistory (open the Website)", action: {
                            if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2") {
                                NSWorkspace.shared.open(url)
                            }
                        }),
                        .init(text: "Rate CopyHistory✨", action: {
                            SKStoreReviewController.requestReview()
                        })

                    ])

                    Text(versionString)

                } label: {
                    Image(systemName: "latch.2.case")
                        .font(.title)
                }
                .frame(width: 50)
                .accentColor(.white)

                Spacer()
                Button(action: {
                    isAlertPresented = true
                }, label: {
                    Image(systemName: "trash")
                })
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)
            VStack {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }, label: {
                    Text("Quit CopyHistory")
                })
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }
}

struct MenuItems: View {
    struct Content: Identifiable {
        var id: String { text }
        let text: String
        let action: () -> Void
    }

    let contents: [Content]
    var body: some View {
        ForEach(contents) { content in
            Button(action: {
                content.action()
            }, label: {
                Text(content.text)
            })
            Divider()
        }
    }
}

struct KeyboardCommandButtons: View {
    struct Key: Identifiable {
        let id: UUID = .init()
        let main: KeyEquivalent
        let sub: EventModifiers
    }

    let action: () -> Void
    let keys: [Key]
    var body: some View {
        Group {
            ForEach(keys) { key in
                Button(action: {
                    action()
                }, label: {}).keyboardShortcut(key.main, modifiers: key.sub)
            }
        }
        .frame(width: .zero, height: .zero)
        .opacity(0)
    }
}

struct Row: View, Equatable {
    let item: CopiedItem
    let favorite: Bool
    let didSelected: (CopiedItem) -> Void
    let favoriteButtonDidTap: (CopiedItem) -> Void
    let deleteButtonDidTap: (CopiedItem) -> Void
    let isFocused: Bool
    @Binding var isExpanded: Bool // to render realtime, using @Binding
    @Binding var isShowingRTF: Bool
    @Binding var isShowingHTML: Bool
    var body: some View {
        VStack {
            HStack {
                if isFocused {
                    Color.mainAccent.frame(width: 5, alignment: .leading)
                }
                Button(action: {
                    withAnimation {
                        didSelected(item)
                    }

                }, label: {
                    ZStack {
                        Color.mainViewBackground

                        // spreading Button's Taparea was very difficult , but ZStack + Color make it
                        // TODO: survey for alternative to Color
                        //
                        //
                        // https://stackoverflow.com/questions/57333573/swiftui-button-tap-only-on-text-portion
                        // https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-tappable-button

                        HStack {
                            Group {
                                if let content = item.content, let image = NSImage(data: content) {
                                    Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 300)
                                } else if isShowingRTF, let attributedString = item.attributeString {
                                    Text(AttributedString(attributedString))

                                } else if isShowingHTML, let attributedString = item.htmlString {
                                    Text(AttributedString(attributedString))
                                } else if let url = item.fileURL {
                                    // TODO:
                                    // I want to show images from fileURL,
                                    // but images disappear next time when it's shown
                                    //                                if let image = NSImage(contentsOf: url) {
                                    //                                    Image(nsImage: image).resizable().scaledToFit()
                                    //                                } else {
                                    Text("\(url.absoluteString)")
                                        .font(.callout)
                                    //                                }
                                } else {
                                    Text(item.name ?? "No Name").font(.callout)
                                }
                            }.padding(.vertical, 8).lineLimit(isExpanded ? 20 : 1)

                            Spacer()
                        }
                    }

                })

                VStack(alignment: .trailing) {
                    Text(item.contentTypeString ?? "").font(.caption)
                    Text("\(item.binarySizeString)").font(.caption)
                }
                Button(action: {
                    favoriteButtonDidTap(item)
                }, label: {
                    Image(systemName: favorite ? "star.fill" : "star")
                        .foregroundColor(favorite ? Color.mainAccent : Color.primary)
                        .frame(width: 44, height: 44)
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                })
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    deleteButtonDidTap(item)
                }, label: {
                    Image(systemName: "trash.fill").foregroundColor(.secondary)
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        Divider()
    }

    static func == (lhs: Row, rhs: Row) -> Bool {
        // This comparation make Row stop unneeded rendering.
        return lhs.isFocused == rhs.isFocused &&
            lhs.favorite == rhs.favorite
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PasteboardService.build())
    }
}

extension Color {
    static var mainViewBackground = Color("mainViewBackground")
    static var mainAccent = Color("AccentColor")
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
