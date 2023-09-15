//
//  ContentsView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI

extension MainView {
    @ViewBuilder
    func ContentsView() -> some View {
        ScrollView {
            // there is a mysterious plain view at the top of the scrollview and it overlays this content. so this is put here
            Spacer()
            ScrollViewReader { proxy in
                LazyVStack(spacing: 0) {
                    // ・This doesn't make ScrollView + ForEach make additional padding, https://www.reddit.com/r/SwiftUI/comments/e607z3/swiftui_scrollview_foreach_padding_weird/
                    // ・Lazy improves the performance of the inclement search.
                    // However Lazy make selecting cell work weird...

                    ForEach(Array(zip(viewModel.copiedItems.indices, viewModel.copiedItems)), id: \.1.dataHash) { index, item in

                        Row(item: item,
                            favorite: item.favorite,
                            isFocused: index == focusedItemIndex, itemAction: $itemAction,
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
                KeyboardCommandButtons(action: { scroll(proxy: proxy, direction: .down) }, keys:
                                        [.init(main: .downArrow, sub: .command), .init(main: "j", sub: .command)])

                KeyboardCommandButtons(action: { scroll(proxy: proxy, direction: .up) }, keys:
                                        [.init(main: .upArrow, sub: .command), .init(main: "k", sub: .command)])
                Shortcuts()
            }
        }
    }

    enum Direction {
        case up
        case down
    }

    func scroll(proxy: ScrollViewProxy, direction: Direction) {
        if viewModel.copiedItems.isEmpty {
            return
        }
        let _focusedItemIndex: Int
        switch direction {
        case .down:
            if let i = focusedItemIndex, viewModel.copiedItems.count - 1 > i {
                _focusedItemIndex = i + 1
            } else {
                _focusedItemIndex = 0
            }

        case .up:
            if let i = focusedItemIndex, i > 0 {
                _focusedItemIndex = i - 1
            } else {
                _focusedItemIndex = viewModel.copiedItems.count - 1
            }
        }
        focusedItemIndex = _focusedItemIndex
        proxy.scrollTo(viewModel.copiedItems[_focusedItemIndex].dataHash)
    }
}

struct Row: View, Equatable {
    let item: CopiedItem
    let favorite: Bool
    let isFocused: Bool
    @FocusState var memoFocusState: Bool

    @Binding var isExpanded: Bool // to render realtime, using @Binding
    @Binding var isShowingRTF: Bool
    @Binding var isShowingHTML: Bool
    @State var memo: String
    @Binding var itemAction: MainView.ItemAction?
    init(item: CopiedItem,
         favorite: Bool,
         isFocused: Bool,
         itemAction: Binding<MainView.ItemAction?>,
         isExpanded: Binding<Bool>,
         isShowingRTF: Binding<Bool>,
         isShowingHTML: Binding<Bool>) {
        self.item = item
        self.favorite = favorite
        self.isFocused = isFocused
        _itemAction = itemAction
        _isExpanded = isExpanded
        _isShowingRTF = isShowingRTF
        _isShowingHTML = isShowingHTML
        memo = item.memo ?? ""
    }

    var body: some View {
        VStack {
            HStack {
                if isFocused {
                    Color.mainAccent.frame(width: 5, alignment: .leading)
//                    KeyboardCommandButtons(
//                        action: {
//                            self.memoFocusState = true
//                        },
//                        keys: [.init(main: "i", sub: .command)]
//                    )
                }

                ZStack {
                    Color.mainViewBackground.opacity(0.1)

                    // spreading Button's Tap area was very difficult , but ZStack + Color make it but .clear is not available
                    // TODO: survey for alternative to Color
                    //
                    //
                    // https://stackoverflow.com/questions/57333573/swiftui-button-tap-only-on-text-portion
                    // https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-a-tappable-button
                    VStack(alignment: .leading) {
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

                                    FileImageView(url: url)
                                } else {
                                    Text(item.name ?? "No Name").font(.callout)
                                }
                            }.padding(.vertical, memo.isEmpty ? 8 : 4).lineLimit(isExpanded ? 20 : 1)

                            Spacer()
                        }
                        if !memo.isEmpty {
                            Text(memo)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .padding(.bottom, 4)
                        }
                    }
                }.onTapGesture {
                    withAnimation {
                        itemAction = .init(item: item, action: .select)
                    }
                }

                VStack(alignment: .trailing) {
                    Text(item.contentTypeString ?? "").font(.caption)
                    Text("\(item.binarySizeString)").font(.caption)
                }

                TextField("", text: $memo)
                    .focused($memoFocusState)
                    .onSubmit({
                        itemAction = .init(item: item, action: .memoEdited(memo))
                    }).frame(width: 26)

                Image(systemName: favorite ? "star.fill" : "star")
                    .foregroundColor(favorite ? Color.mainAccent : Color.primary)
                    .frame(width: 30, height: 44)
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                    .onTapGesture {
                        itemAction = .init(item: item, action: .favorite)
                    }

                Image(systemName: "trash.fill").foregroundColor(.secondary).onTapGesture {
                    itemAction = .init(item: item, action: .delete)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        Divider()
    }

    /// This comparation make Row stop unneeded rendering.
    static func == (lhs: Row, rhs: Row) -> Bool {
        return lhs.isFocused == rhs.isFocused
        && lhs.favorite == rhs.favorite
    }
}

struct FileImageView: View {
    let url: URL
    @State var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFit()
            } else {
                Text("\(url.absoluteString)")
                    .font(.callout)
            }
        }.task { // デフォルトでメインスレッドなんだな。
            if image == nil {
//                print("inside task", Thread.isMainThread)
//                Task.detached { // ここでTaskを使ってもでもメインスレッド
//                    print("outside task",Thread.isMainThread)
//                    image = NSImage(contentsOf: url) // isMainThreadがfalseなのにここで以下のエラがでる。。
//                    
//                    ///This method should not be called on the main thread as it may lead to UI unresponsiveness.
//                }

                /// 結局Xcodeのバグっぽい。
                /// https://ios-docs.dev/this-method-should/

//                image = await loadImage(from: url)
            }

        }
    }

    func loadImage(from url: URL) async -> NSImage? {
        return NSImage(contentsOf: url)
    }
}
extension NSImage: @unchecked Sendable {}

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
                }, label: {})
                .keyboardShortcut(key.main, modifiers: key.sub)
            }
        }
        .frame(width: .zero, height: .zero)
        .opacity(0)
    }
}
