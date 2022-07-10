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
            List(pasteboardService.copiedItems){ item in
                Row(item: item,
                    didSelected: { item in pasteboardService.didSelected(item)},
                    favoriteButtonDidTap: { item in pasteboardService.favoriteButtonDidTap(item) },
                    deleteButtonDidTap: { item in pasteboardService.deleteButtonDidTap(item) }
                )
            }
            .border(.separator, width: 1.0)
            .listStyle(.inset(alternatesRowBackgrounds: false))
            .onAppear {
                isFocus = true
            }
            HStack {
                
                Button(action: {
                    NSApplication().terminate(nil)
                }, label: {
                    Image(systemName: "xmark.circle")
                })
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
                    title: Text("お気に入り以外の\nコピー履歴を削除します"),
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

struct Row: View  {
    let item: CopiedItem
    let didSelected: ((CopiedItem) -> Void)
    let favoriteButtonDidTap: ((CopiedItem) -> Void)
    let deleteButtonDidTap: ((CopiedItem) -> Void)

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    didSelected(item)
                }, label: {
                    Text(item.name ?? "")
                        .font(.body)
                    Spacer()
                })
                Button(action: {
                    favoriteButtonDidTap(item)
                }, label: {
                    Image(systemName: item.favorite ? "star.fill" : "star")
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
        .background(Color.white.opacity(0.1))
        .buttonStyle(PlainButtonStyle())
    }

}
//

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PasteboardService.build())
    }
}
