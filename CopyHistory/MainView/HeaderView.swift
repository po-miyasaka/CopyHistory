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
                sortMenu()
                memoButton()
                reminderFilterButton()
                favoriteButton()
            }
        }
    }

    func searchBar() -> some View {
        HStack(alignment: .center, spacing: 10) {
            TextField(isShowingKeyboardShortcuts ? "Search: ⌘ + f" : "Search", text: $viewModel.searchText)

                .focused($isFocus)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.searchText, perform: { _ in
                    focusedItemIndex = nil
                })
                .foregroundColor(.primary)
            Text("\(viewModel.copiedItems.count)")
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
                Text("Reminders:"); Text("⌘ + t")
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
                    viewModel.isShowingOnlyMemoed.toggle()
                }

            }, label: {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(viewModel.isShowingOnlyMemoed ? Color.mainAccent : Color.primary)
            })
            .keyboardShortcut("p", modifiers: .command)

            if isShowingKeyboardShortcuts {
                Text("⌘ + p").font(.caption).foregroundColor(.gray).padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    func sortMenu() -> some View {
        Menu {
            Picker("Sort by", selection: $viewModel.sort.field) {
                ForEach(ItemSort.Field.allCases) { field in
                    Text(field.title).tag(field)
                }
            }
            .pickerStyle(.inline)
            Picker("Order", selection: $viewModel.sort.ascending) {
                Text("Descending").tag(false)
                Text("Ascending").tag(true)
            }
            .pickerStyle(.inline)
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sort items (ignored while showing only reminders)")
    }

    @ViewBuilder
    func reminderFilterButton() -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    viewModel.isShowingOnlyReminder.toggle()
                }
            }, label: {
                Image(systemName: viewModel.isShowingOnlyReminder ? "clock.fill" : "clock")
                    .foregroundColor(viewModel.isShowingOnlyReminder ? Color.mainAccent : Color.primary)
            })
            .keyboardShortcut("t", modifiers: .command)
            .help("Show only items with reminders, soonest first")

            if isShowingKeyboardShortcuts {
                Text("⌘ + t").font(.caption).foregroundColor(.gray).padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    func favoriteButton() -> some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation {
                    viewModel.isShowingOnlyFavorite.toggle()
                }

            }, label: {
                Image(systemName: viewModel.isShowingOnlyFavorite ? "star.fill" : "star")
                    .foregroundColor(viewModel.isShowingOnlyFavorite ? Color.mainAccent : Color.primary)
            })
            .keyboardShortcut("s", modifiers: .command)

            if isShowingKeyboardShortcuts {
                Text("⌘ + s").font(.caption).foregroundColor(.gray).padding(.top, 2)
            }
        }
    }
}
