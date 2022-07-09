//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    @FocusState var isFocus
    @State var isAlertPresented: Bool = false
    var body: some View {
        Group {
            TextField("search text ", text: $pasteboardService.searchText)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .focused($isFocus)
                .textFieldStyle(.roundedBorder)
                .onChange(of: pasteboardService.searchText, perform: { _ in pasteboardService.search() })

            List {
                ForEach(pasteboardService.copiedItems) { item in
                    Button(action: {
                        pasteboardService.didSelected(item)
                    }, label: {
                        VStack {
                            HStack {
                                Text(item.name ?? "")
                                    .font(.body)
                                    .padding()
                                Spacer()
                                Button(action: {
                                    pasteboardService.deleteButtonDidTap(item)
                                }, label: {
                                    Image(systemName: "trash.fill")
                                })
                                    .buttonStyle(PlainButtonStyle())
                            }
                            .frame(height: 30)
                            Divider().padding(EdgeInsets())
                        }
                        .background(Color.white.opacity(0.1))

                    })
                        .buttonStyle(PlainButtonStyle())
                }
            }
            .border(.separator, width: 1.0)
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .onAppear {
                isFocus = true
            }
            .keyboardShortcut(.return, modifiers: [.command])
            HStack {
                Text("\(pasteboardService.copiedItems.count)")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                Spacer()

                Button(action: {
                    isAlertPresented = true
                }, label: {
                    Image(systemName: "trash.circle.fill")
                })
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .alert(
            isPresented: $isAlertPresented,
            content: {
                Alert(
                    title: Text("お気に入り以外のコピー履歴を削除しますか？"),
                    primaryButton: Alert.Button.destructive(
                        Text("削除する"),
                        action: {
                            pasteboardService.clearAll()
                        }
                    ),
                    secondaryButton: Alert.Button.cancel(Text("やめる"), action: {})
                )
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PasteboardService.build())
    }
}
