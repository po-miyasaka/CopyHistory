//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    @AppStorage("isShowingKeyboardShortcuts") var isShowingKeyboardShortcuts = true
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    @State var focusedItemIndex: Int?

    let versionString: String = {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return "\(version ?? "") (\(build ?? ""))"
    }()

    var body: some View {
        Group {
            Header()
            MainView()
            Footer()
            KeyboardShortcutCommands()
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

    func selectDown() {
        if let i = focusedItemIndex, pasteboardService.copiedItems.count > i {
            focusedItemIndex = i + 1
        } else {
            focusedItemIndex = 0
        }
    }

    func selectUp() {
        if let i = focusedItemIndex, i >= 0 {
            focusedItemIndex = i - 1
        } else {
            focusedItemIndex = pasteboardService.copiedItems.endIndex
        }
    }


    @ViewBuilder
    func KeyboardShortcutCommands() -> some View {
        HStack{
            Button(action: {
                isFocus = true
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut("f", modifiers: .command)

            Button(action: {
                selectDown()
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut(.downArrow, modifiers: .command)

            Button(action: {
                selectDown()
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut("j", modifiers: .command)

            Button(action: {
                selectUp()
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut(.upArrow, modifiers: .command)

            Button(action: {
                selectUp()
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut("k", modifiers: .command)

            Button(action: {
                if let i = focusedItemIndex, pasteboardService.copiedItems.endIndex > i {
                    pasteboardService.didSelected(pasteboardService.copiedItems[i])
                    focusedItemIndex = nil
                    NSApplication.shared.deactivate()
                }
            }, label: {})
            .opacity(.leastNonzeroMagnitude)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .frame(width: .leastNonzeroMagnitude, height: .leastNonzeroMagnitude)
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
                    VStack(alignment: .leading) {
                        Text("     Up: ⌘ + ↑ or k")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                            .padding(.bottom, 1)

                        Text(" Down: ⌘ + ↓ or j")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                            .padding(.bottom, 1)

                        Text("Select: ⌘ + ↩")
                            .font(.caption)
                            .foregroundColor(Color.gray)
                            .padding(.bottom, 1)

                    }
                }

                Spacer()

                VStack(spacing:0) {
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
        Group {
            List(Array(zip(pasteboardService.copiedItems.indices, pasteboardService.copiedItems)), id: \.1.dataHash) { index, item in
                Row(item: item,
                    didSelected: { item in
                    focusedItemIndex = nil
                    pasteboardService.didSelected(item)
                    NSApplication.shared.deactivate()
                },
                    favoriteButtonDidTap: { item in pasteboardService.favoriteButtonDidTap(item) },
                    deleteButtonDidTap: { item in pasteboardService.deleteButtonDidTap(item) },
                    isFocused: index == focusedItemIndex
                )


            }
            .border(.separator, width: 1.0)
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .onAppear {
                isFocus = true
            }
        }
    }

    @ViewBuilder
    func Footer() -> some View {
        Group {
            HStack {
                Menu {
                    Button(action: {
                        isShowingKeyboardShortcuts.toggle()
                    }, label: {
                        Text( isShowingKeyboardShortcuts ? "Hide keyboard shortcuts" : "Show keyboard shortcuts")
                    })
                    Divider()
                    Button(action:{
                        if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2_shortcut_launch") {
                            NSWorkspace.shared.open(url)
                        }
                    }, label: {
                        Text("About launching with a keyboard shortcut (open the Website)")
                    })
                    Divider()
                    Button(action: {
                        if let url = URL(string: "https://miyashi.app/articles/copy_history_mark_2") {
                            NSWorkspace.shared.open(url)
                        }
                    }, label: {
                        Text("About CopyHistory (open the Website)")
                    })
                    Divider()
                    Button(action: {
                        SKStoreReviewController.requestReview()
                    }, label: {
                        Text( "Rate CopyHistory✨")
                    })
                    Divider()
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

struct Row: View {
    let item: CopiedItem
    let didSelected: (CopiedItem) -> Void
    let favoriteButtonDidTap: (CopiedItem) -> Void
    let deleteButtonDidTap: (CopiedItem) -> Void
    let isFocused: Bool
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        didSelected(item)
                    }

                }, label: {
                    VStack {
                        HStack {
                            Text(item.name ?? "No Name")
                                .font(.callout)
                                .foregroundColor(isFocused ? .mainAccent : .primary)
                            Spacer()
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(RoundedRectangle(cornerRadius: 20))
                })

                VStack(alignment: .trailing) {
                    Text(item.contentTypeString ?? "").font(.caption)
                    Text("\(item.binarySizeString)").font(.caption)
                }
                Button(action: {
                    favoriteButtonDidTap(item)
                }, label: {
                    Image(systemName: item.favorite ? "star.fill" : "star")
                        .foregroundColor(item.favorite ? Color.mainAccent : Color.primary)
                        .frame(minHeight: 44)
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
            .frame(height: 30)
            Divider().padding(EdgeInsets())
        }
        .buttonStyle(PlainButtonStyle())
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
