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
    var body: some View {
        TextField("search text ", text: $pasteboardService.searchText)
            .padding()
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

        .listStyle(.inset(alternatesRowBackgrounds: false))
        .onAppear {
            isFocus = true
        }
        .keyboardShortcut(.return, modifiers: [.command])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PasteboardService.build())
    }
}
