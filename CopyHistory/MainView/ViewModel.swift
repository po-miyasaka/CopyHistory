//
//  ViewModel.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/27.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ViewModel: ObservableObject {
    private static let displayedItemCountDefaultValue = 100

    @Published var searchText: String = ""
    @Published var isShowingOnlyFavorite: Bool = false
    @Published var isShowingOnlyMemoed: Bool = false
    @Published private(set) var copiedItems: [CopiedItem] = []
    @Published private(set) var displayedItemCount: Int = {
        let value = UserDefaults.standard.integer(forKey: "displayedItemCount")
        if value == 0 {
            return displayedItemCountDefaultValue
        } else {
            return max(value, 1)
        }
    }() {
        didSet {
            UserDefaults.standard.setValue(displayedItemCount, forKey: "displayedItemCount")
        }
    }

    lazy var displayedItemCountBinding: Binding<String> = .init(
        get: { [weak self] in
            String(self?.displayedItemCount ?? Self.displayedItemCountDefaultValue)
        },
        set: { [weak self] in
            self?.displayedItemCount = Int($0) ?? 0
        }
    )

    private lazy var pasteboardService = PasteboardService.build(createCopiedItem: { [weak self] in
        self?.repository.create()
    }, getItem: { [weak self] in
        self?.repository.getItem(hash: $0)
    }, saveItem: { [weak self] in
        self?.repository.update()
    })

    private let repository = CopiedItemRepository()
    private var cancellables: [AnyCancellable] = []

    private init() {}

    static func build() -> ViewModel {
        let viewModel = ViewModel()
        viewModel.setup()
        return viewModel
    }

    func setup() {
        _ = pasteboardService // Todo: 内部のTimerを稼働させる必要がありイニシャライズを行う必要があるが、selfをキャプチャしたクロージャを渡している関係でlazyにしてあるため一度参照している且つが設計を見直す。
        Publishers.CombineLatest4(
            $searchText.debounce(for: 0.3, scheduler: DispatchQueue.main).eraseToAnyPublisher(), // TODO: How should Scheduler be set to improve performance.
            $isShowingOnlyFavorite.eraseToAnyPublisher(),
            $isShowingOnlyMemoed.eraseToAnyPublisher(),
            $displayedItemCount.debounce(for: 0.5, scheduler: DispatchQueue.main).eraseToAnyPublisher()
        )
        .sink {[weak self] (arg0) in
            let (searchText, isShowingOnlyFavorite, isShowingOnlyMemoed, displayedItemCount) = arg0
            self?.repository.requestCopiedItems(with: searchText, isShowingOnlyFavorite: isShowingOnlyFavorite, isShowingOnlyMemoed: isShowingOnlyMemoed, limit: displayedItemCount)
        }.store(in: &cancellables)

        // TODO: このタスクの使い方
        Task {  [weak self] in
            if let stream = self?.repository.stream {
                for await copiedItems in stream {
                        self?.copiedItems = copiedItems
                }
            }
        }

    }
    func didSelected(_ copiedItem: CopiedItem) {
        pasteboardService.apply(copiedItem)
        copiedItem.updateDate = Date()
        repository.update()
    }

    func toggleFavorite(_ copiedItem: CopiedItem) {
        copiedItem.favorite.toggle()
        repository.update()
    }

    func saveMemo(_ copiedItem: CopiedItem, memo: String) {
        copiedItem.memo = memo
        repository.update()
    }

    func delete(_ copiedItem: CopiedItem) {
        repository.delete(object: copiedItem)
    }

    func clearAll() {
        repository.deleteAll()
    }
}
