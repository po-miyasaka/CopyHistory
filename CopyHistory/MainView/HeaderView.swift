//
//  HeaderView.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/04/04.
//

import SwiftUI

extension MainView {
    
    @ViewBuilder
    func Header() -> some View {
        VStack(spacing: 16) {
            searchBar()
            HStack(alignment: .bottom) {
                if isShowingKeyboardShortcuts {
                    shortcutsList()
                }
                Spacer()
                memoButton()
                favoriteButton()
            }
        }
    }
    
    
    func searchBar() -> some View {
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
        }
    }
    
    @ViewBuilder
    func shortcutsList() -> some View {
        let columns = [GridItem(.flexible(minimum: 80), spacing: 8, alignment: .trailing), GridItem(.flexible(minimum: 150), spacing: 8)]
        
        
        
        LazyVGrid(columns: columns, alignment: .leading, spacing: 0, content: {
            Group {
                Text("Up:"); Text("⌘ + ↑ or k")
                Text("Down:"); Text("⌘ + ↓ or j")
                Text("Select:"); Text("⌘ + ↩")
                Text("Delete:"); Text("⌘ + ⇧ + d")
                Text("Star:"); Text("⌘ + o")
            }
            Group {
                Text("Write a memo:"); Text("⌘ + i")
                Text(isExpanded ? "Minify cells:" : "Expand cells:"); Text("⌘ + e")
                Text(isShowingRTF ? "Stop Showing as RTF:" : "Show as RTF (slow):"); Text("⌘ + r")
                Text(isShowingHTML ? "Stop Showing as HTML:" : "Show as HTML (slow):"); Text("⌘ + h")
            }
        })
        .font(.caption)
        .foregroundColor(Color.gray)
        .padding(.bottom, 1)
        
        
        
    }
    
    @ViewBuilder
    func memoButton() -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    pasteboardService.filterMemoed()
                }
                
            }, label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(pasteboardService.isShowingOnlyMemoed ? Color.mainAccent : Color.primary)
            })
            .keyboardShortcut("p", modifiers: .command)
            
            if isShowingKeyboardShortcuts {
                Text("⌘ + p").font(.caption).foregroundColor(.gray).padding(.top, 2)
            }
        }
    }
    
    @ViewBuilder
    func favoriteButton() -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    pasteboardService.filterFavorited()
                }
                
            }, label: {
                Image(systemName: pasteboardService.isShowingOnlyFavorite ? "star.fill" : "star")
                    .foregroundColor(pasteboardService.isShowingOnlyFavorite ? Color.mainAccent : Color.primary)
            })
            .keyboardShortcut("s", modifiers: .command)
            
            if isShowingKeyboardShortcuts {
                Text("⌘ + s").font(.caption).foregroundColor(.gray).padding(.top, 2)
            }
        }
    }
}
