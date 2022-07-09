//
//  ContentView.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject var pasteboardService: PasteboardService = .build()
    
    var body: some View {
        NavigationView{
            List {
                ForEach(pasteboardService.copiedItems) { item in
                    Button(action: {
                        pasteboardService.didSelected(item)
                    },label: {
                        
                        VStack {
                            HStack {
                                Text(item.name ?? "")
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(3)
                                    .padding()
                                Spacer()
                                Button(action: {
                                    pasteboardService.deleteButtonDidTap(item)
                                },label: {
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
            .searchable(text: $pasteboardService.searchText, prompt: "")
            .onChange(of: pasteboardService.searchText, perform: { text in
                pasteboardService.search()
            })
        }.navigationViewStyle(.columns)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(PasteboardService.build())
    }
}
