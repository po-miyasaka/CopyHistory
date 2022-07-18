//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI

struct ContentView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    var body: some View {
        Group {
            TextField("search (⌘ + f)", text: $pasteboardService.searchText)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .focused($isFocus)
                .textFieldStyle(.roundedBorder)
                .onChange(of: pasteboardService.searchText, perform: { _ in pasteboardService.search() })
            HStack {
                Text("\(pasteboardService.copiedItems.count)")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                Spacer()

                Button(action: {
                    pasteboardService.favoriteFilterButtonDidTap()
                }, label: {
                    Image(systemName: pasteboardService.isShowingOnlyFavorite ? "star.fill" : "star")
                })
            }
            .padding(.horizontal)
            List(pasteboardService.copiedItems) { item in
                Row(item: item,
                    didSelected: { item in pasteboardService.didSelected(item) },
                    favoriteButtonDidTap: { item in pasteboardService.favoriteButtonDidTap(item) },
                    deleteButtonDidTap: { item in pasteboardService.deleteButtonDidTap(item) })
            }
            .border(.separator, width: 1.0)
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .onAppear {
                isFocus = true
            }
            HStack {
                Button(action: {
                    isFocus = true
                }, label: {})
                    .opacity(.leastNonzeroMagnitude)
                    .keyboardShortcut("f", modifiers: .command)
                Spacer()

                Button(action: {
                    isAlertPresented = true
                }, label: {
                    Image(systemName: "trash.circle.fill")
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
}

struct Row: View {
    let item: CopiedItem
    let didSelected: (CopiedItem) -> Void
    let favoriteButtonDidTap: (CopiedItem) -> Void
    let deleteButtonDidTap: (CopiedItem) -> Void

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    didSelected(item)
                }, label: {
                    VStack {
                        HStack {
                            Text(item.name ?? "No Name")
                                .font(.body)
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
                        .frame(minHeight: 44)
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                })
                .buttonStyle(PlainButtonStyle())
                Button(action: {
                    deleteButtonDidTap(item)
                }, label: {
                    Image(systemName: "trash.fill")
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
}
