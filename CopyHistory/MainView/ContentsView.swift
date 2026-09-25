//
//  ContentsView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI
import Algorithms

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, NSImage>()
    private let maxThumbnailHeight: CGFloat = 300

    private init() {
        cache.countLimit = 200
    }

    func thumbnail(for dataHash: String?, content: Data?) -> NSImage? {
        guard let dataHash = dataHash else { return nil }
        let key = dataHash as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let content = content, let original = NSImage(data: content) else { return nil }
        let thumbnail = downsize(original)
        cache.setObject(thumbnail, forKey: key)
        return thumbnail
    }

    nonisolated func thumbnailAsync(for dataHash: String?, content: @Sendable @escaping () -> Data?) async -> NSImage? {
        guard let dataHash = dataHash else { return nil }
        let key = dataHash as NSString
        if let cached = await MainActor.run(body: { cache.object(forKey: key) }) {
            return cached
        }
        return await Task.detached(priority: .utility) { [maxThumbnailHeight] in
            guard let content = content(), let original = NSImage(data: content) else { return nil as NSImage? }
            let size = original.size
            if size.height <= maxThumbnailHeight && size.width <= maxThumbnailHeight * 2 {
                return original
            }
            let scale = min(maxThumbnailHeight / size.height, (maxThumbnailHeight * 2) / size.width)
            let newSize = NSSize(width: size.width * scale, height: size.height * scale)
            let thumbnail = NSImage(size: newSize)
            thumbnail.lockFocus()
            original.draw(in: NSRect(origin: .zero, size: newSize),
                          from: NSRect(origin: .zero, size: size),
                          operation: .copy,
                          fraction: 1.0)
            thumbnail.unlockFocus()
            return thumbnail
        }.value
    }

    private func downsize(_ image: NSImage) -> NSImage {
        let size = image.size
        if size.height <= maxThumbnailHeight && size.width <= maxThumbnailHeight * 2 {
            return image
        }
        let scale = min(maxThumbnailHeight / size.height, (maxThumbnailHeight * 2) / size.width)
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let thumbnail = NSImage(size: newSize)
        thumbnail.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: size),
                   operation: .copy,
                   fraction: 1.0)
        thumbnail.unlockFocus()
        return thumbnail
    }
}

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
                    
                    
                    ForEach(viewModel.copiedItems.indexed(), id: \.element.dataHash) { index, item in
                        
                        Row(item: item,
                            favorite: item.favorite,
                            reminderDate: item.reminderDate,
                            isFocused: index == focusedItemIndex, itemAction: {
                            itemAction = $0
                        },
                            index: index,
                            onHoverContent: { focusedItemIndex = $0 },
                            isExpanded: $isExpanded,
                            isShowingRTF: $isShowingRTF,
                            isShowingHTML: $isShowingHTML,
                            isShowingDate: $isShowingDate,
                            isShowingUpdatedDate: $isShowingUpdatedDate,
                            isShowingFileInfo: $isShowingFileInfo)
                        .id(item.dataHash)
                    }
                    
                }
                .padding(.horizontal)
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
        guard !viewModel.copiedItems.isEmpty else { return }
        
        let itemCount = viewModel.copiedItems.count
        let newIndex: Int
        
        switch direction {
        case .down:
            newIndex = ((focusedItemIndex ?? -1) + 1) % itemCount
        case .up:
            newIndex = ((focusedItemIndex ?? itemCount) - 1 + itemCount) % itemCount
        }
        
        focusedItemIndex = newIndex
        proxy.scrollTo(viewModel.copiedItems[newIndex].dataHash)
    }
}

struct Row: View, Equatable {
    let item: CopiedItem
    let favorite: Bool
    let reminderDate: Date?
    let isFocused: Bool
    @State private var isShowingReminderPopover = false
    @FocusState var memoFocusState: Bool
    @Binding var isExpanded: Bool // to render realtime, using @Binding
    @Binding var isShowingRTF: Bool
    @Binding var isShowingHTML: Bool
    @Binding var isShowingDate: Bool
    @Binding var isShowingUpdatedDate: Bool
    @Binding var isShowingFileInfo: Bool
    @State var memo: String
    @State private var thumbnailImage: NSImage?
    var itemAction: (MainView.ItemAction) -> Void
    let index: Int
    var onHoverContent: (Int) -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale.current
        return formatter
    }()

    private static let minRowHeight: CGFloat = 44
    private static let cellVerticalMargin: CGFloat = 8

    /// Collapsed rows keep images within the same height as a one-line text row.
    private var imageMaxHeight: CGFloat {
        isExpanded ? 300 : Self.minRowHeight - 16
    }

    private var isImageType: Bool {
        guard let type = item.contentTypeString else { return false }
        return type.contains("image") || type.contains("png") || type.contains("jpeg") || type.contains("tiff") || type.contains("gif") || type.contains("bmp")
    }

    init(item: CopiedItem,
         favorite: Bool,
         reminderDate: Date?,
         isFocused: Bool,
         itemAction: @escaping (MainView.ItemAction) -> Void,
         index: Int,
         onHoverContent: @escaping (Int) -> Void,
         isExpanded: Binding<Bool>,
         isShowingRTF: Binding<Bool>,
         isShowingHTML: Binding<Bool>,
         isShowingDate: Binding<Bool>,
         isShowingUpdatedDate: Binding<Bool>,
         isShowingFileInfo: Binding<Bool>) {
        self.item = item
        self.favorite = favorite
        self.reminderDate = reminderDate
        self.isFocused = isFocused
        self.itemAction = itemAction
        self.index = index
        self.onHoverContent = onHoverContent
        _isExpanded = isExpanded
        _isShowingRTF = isShowingRTF
        _isShowingHTML = isShowingHTML
        _isShowingDate = isShowingDate
        _isShowingUpdatedDate = isShowingUpdatedDate
        _isShowingFileInfo = isShowingFileInfo
        memo = item.memo ?? ""
    }

    var body: some View {
        HStack(spacing: 0) {
            if isFocused {
                Color.mainAccent.frame(width: 5)
                    .padding(.trailing, 4)
                KeyboardCommandButtons(
                    action: {
                        self.memoFocusState = true
                    },
                    keys: [.init(main: "i", sub: .command)]
                )
            }

            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        itemAction(.init(item: item, action: .select))
                    }, label: {

                        ZStack {
                            Color.mainViewBackground.opacity(0.1)

                            VStack(alignment: .leading) {
                                HStack {
                                    Group {
                                        if isImageType {
                                            if let thumbnailImage {
                                                Image(nsImage: thumbnailImage).resizable().scaledToFit().frame(maxHeight: imageMaxHeight)
                                            } else {
                                                ProgressView()
                                                    .frame(maxHeight: imageMaxHeight)
                                            }
                                        } else if isShowingRTF, let attributedString = item.attributeString {
                                            Text(AttributedString(attributedString))

                                        } else if isShowingHTML, let attributedString = item.htmlString {
                                            Text(AttributedString(attributedString))
                                        } else if let url = item.fileURL {
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
                        }
                        .frame(minHeight: Self.minRowHeight)
                    })
                    .onHover { hovering in
                        if hovering { onHoverContent(index) }
                    }

                    if !isFocused {
                        statusButtons
                    }

                    TextField("", text: $memo)
                        .focused($memoFocusState)
                        .onSubmit({
                            itemAction(.init(item: item, action: .memoEdited(memo)))
                        }).frame(width: 26)

                    if isShowingFileInfo || isShowingDate || isShowingUpdatedDate {
                        VStack(alignment: .trailing) {
                            if isShowingFileInfo {
                                Text(item.contentTypeString ?? "").font(.caption)
                                Text("\(item.binarySizeString)").font(.caption)
                            }
                            if isShowingDate, let created = item.createdDate ?? item.updateDate {
                                Text("Saved: \(Self.dateFormatter.string(from: created))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if isShowingUpdatedDate, let updated = item.updateDate {
                                Text("Updated: \(Self.dateFormatter.string(from: updated))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, Self.cellVerticalMargin)

                if isFocused {
                    HStack(alignment: .top, spacing: 8) {
                        actionButtons

                        Group {
                            if isImageType {
                                saveImageButton
                            } else {
                                TransformActionsBar(item: item) { transformAction in
                                    itemAction(.init(item: item, action: .transform(transformAction)))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .task(id: item.dataHash) {
            guard isImageType, thumbnailImage == nil else { return }
            let dataHash = item.dataHash
            let content = item.content
            thumbnailImage = await ThumbnailCache.shared.thumbnailAsync(for: dataHash) { content }
        }
        Divider()
    }

    private static let reminderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("Mdjmm")
        return formatter
    }()

    private var reminderColor: Color {
        guard let reminderDate else { return Color.primary }
        return reminderDate < Date() ? Color.red : Color.mainAccent
    }

    /// Favorite and reminder stay visible (and clickable) while the row is not focused.
    private var statusButtons: some View {
        HStack(spacing: 4) {
            if reminderDate != nil {
                reminderButton()
            }
            if favorite {
                favoriteButton
            }
        }
    }

    private var favoriteButton: some View {
        Button(action: {
            itemAction(.init(item: item, action: .favorite))
        }, label: {
            Image(systemName: favorite ? "star.fill" : "star")
                .foregroundColor(favorite ? Color.mainAccent : Color.primary)
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        })
    }

    private var saveImageButton: some View {
        Button(action: {
            itemAction(.init(item: item, action: .saveImageToDesktop))
        }, label: {
            Label("Save to Desktop…", systemImage: "square.and.arrow.down")
                .font(.caption2)
                .lineLimit(1)
        })
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var actionButtons: some View {
        HStack(spacing: 4) {
            reminderButton()

            favoriteButton

            Button(action: {
                itemAction(.init(item: item, action: .delete))
            }, label: {
                Image(systemName: "trash.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            })
        }
    }

    private func reminderButton() -> some View {
        Button(action: {
            isShowingReminderPopover = true
        }, label: {
            VStack(spacing: 0) {
                Image(systemName: reminderDate == nil ? "clock" : "clock.fill")
                if let reminderDate {
                    Text(Self.reminderFormatter.string(from: reminderDate)).font(.caption2)
                }
            }
            .foregroundColor(reminderColor)
            .frame(minWidth: 30, minHeight: 28)
            .contentShape(Rectangle())
        })
        .popover(isPresented: $isShowingReminderPopover) {
            ReminderPopoverView(
                current: reminderDate,
                onSet: { date in
                    isShowingReminderPopover = false
                    itemAction(.init(item: item, action: .reminder(date)))
                },
                onClear: {
                    isShowingReminderPopover = false
                    itemAction(.init(item: item, action: .reminder(nil)))
                }
            )
        }
    }

    /// This comparation make Row stop unneeded rendering.
    static func == (lhs: Row, rhs: Row) -> Bool {
        return lhs.item.dataHash == rhs.item.dataHash &&
        lhs.index == rhs.index &&
        lhs.isFocused == rhs.isFocused &&
        lhs.favorite == rhs.favorite &&
        lhs.reminderDate == rhs.reminderDate &&
        lhs.isExpanded == rhs.isExpanded &&
        lhs.isShowingRTF == rhs.isShowingRTF &&
        lhs.isShowingHTML == rhs.isShowingHTML &&
        lhs.isShowingDate == rhs.isShowingDate &&
        lhs.isShowingUpdatedDate == rhs.isShowingUpdatedDate &&
        lhs.isShowingFileInfo == rhs.isShowingFileInfo
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
