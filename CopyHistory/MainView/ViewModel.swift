//
//  ViewModel.swift
//  CopyHistory
//
//  Created by po_miyasaka on 2023/08/27.
//

import Foundation
import Combine
import SwiftUI
import CryptoKit

@MainActor
final class ViewModel: ObservableObject {
    private static let displayedItemCountDefaultValue = 100

    @Published var searchText: String = ""
    @Published var isShowingOnlyFavorite: Bool = false
    @Published var isShowingOnlyMemoed: Bool = false
    @Published var isShowingOnlyReminder: Bool = false
    @Published var sort: ItemSort = {
        UserDefaults.standard.data(forKey: "itemSort")
            .flatMap { try? JSONDecoder().decode(ItemSort.self, from: $0) } ?? ItemSort()
    }() {
        didSet {
            guard let data = try? JSONEncoder().encode(sort) else { return }
            UserDefaults.standard.set(data, forKey: "itemSort")
        }
    }
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
        repository.backfillMissingAttributes()
        let filters = Publishers.CombineLatest4($isShowingOnlyFavorite, $isShowingOnlyMemoed, $isShowingOnlyReminder, $sort)
        Publishers.CombineLatest3(
            $searchText.debounce(for: 0.3, scheduler: DispatchQueue.main).eraseToAnyPublisher(), // TODO: How should Scheduler be set to improve performance.
            filters.eraseToAnyPublisher(),
            $displayedItemCount.debounce(for: 0.5, scheduler: DispatchQueue.main).eraseToAnyPublisher()
        )
        .sink {[weak self] (arg0) in
            let (searchText, (isShowingOnlyFavorite, isShowingOnlyMemoed, isShowingOnlyReminder, sort), displayedItemCount) = arg0
            self?.repository.requestCopiedItems(with: searchText, isShowingOnlyFavorite: isShowingOnlyFavorite, isShowingOnlyMemoed: isShowingOnlyMemoed, isShowingOnlyReminder: isShowingOnlyReminder, sort: sort, limit: displayedItemCount)
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

    func didSelectWithTransform(_ copiedItem: CopiedItem, transform: TransformAction) {
        guard let rawString = copiedItem.rawString,
              let transformed = TextTransformer.apply(transform, to: rawString)
        else { return }
        pasteboardService.applyTransformed(transformed)
        copiedItem.updateDate = Date()
        repository.update()
    }

    func exportCSV() {
        do {
            let rows = try repository.fetchAllForExport().map(CSVExportRow.init(item:))
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.commaSeparatedText]
            panel.nameFieldStringValue = "CopyHistory-\(Self.exportDateFormatter.string(from: Date())).csv"
            NSApp.activate(ignoringOtherApps: true)
            guard FilePanelPin.run(panel) == .OK, let url = panel.url else { return }
            try CSVExporter.makeCSV(rows: rows).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = String(localized: "Failed to export CSV")
            alert.runModal()
        }
    }

    private static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()

    func toggleFavorite(_ copiedItem: CopiedItem) {
        copiedItem.favorite.toggle()
        repository.update()
    }

    func saveMemo(_ copiedItem: CopiedItem, memo: String) {
        copiedItem.memo = memo
        repository.update()
    }

    func setReminder(_ copiedItem: CopiedItem, date: Date?) {
        guard let dataHash = copiedItem.dataHash else { return }
        copiedItem.reminderDate = date
        repository.update()
        guard let date else {
            ReminderService.cancel(ids: [dataHash])
            return
        }
        scheduleReminder(dataHash: dataHash, body: reminderBody(for: copiedItem), date: date, reportsFailure: true)
    }

    func saveImageToDesktop(_ copiedItem: CopiedItem) {
        do {
            guard let png = copiedItem.imagePNGData else { throw ImageSaveError.unreadableImage }
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = "CopyHistory-\(Self.exportDateFormatter.string(from: Date())).png"
            panel.directoryURL = Self.realDesktopURL
            NSApp.activate(ignoringOtherApps: true)
            guard FilePanelPin.run(panel) == .OK, let url = panel.url else { return }
            try png.write(to: url, options: .atomic)
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = String(localized: "Failed to save the image")
            alert.runModal()
        }
    }

    /// Inside the sandbox `.desktopDirectory` points into the app container, so resolve the real home instead.
    private static var realDesktopURL: URL? {
        guard let entry = getpwuid(getuid()), let home = entry.pointee.pw_dir else { return nil }
        return URL(fileURLWithPath: String(cString: home)).appendingPathComponent("Desktop")
    }

    func delete(_ copiedItem: CopiedItem) {
        if let dataHash = copiedItem.dataHash {
            ReminderService.cancel(ids: [dataHash])
        }
        repository.delete(object: copiedItem)
    }

    func clearAll() {
        ReminderService.cancel(ids: copiedItems.filter { !$0.favorite }.compactMap(\.dataHash))
        repository.deleteAll()
    }

    private func reminderBody(for item: CopiedItem) -> String {
        let memo = item.memo ?? ""
        return memo.isEmpty ? String((item.name ?? "").prefix(100)) : memo
    }

    private func scheduleReminder(dataHash: String, body: String, date: Date, reportsFailure: Bool) {
        Task {
            do {
                try await ReminderService.schedule(id: dataHash, body: body, at: date)
            } catch {
                NSLog("Failed to schedule reminder: \(error)")
                if reportsFailure { NSAlert(error: error).runModal() }
            }
        }
    }

    func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.allowsMultipleSelection = false
        NSApp.activate(ignoringOtherApps: true)
        guard FilePanelPin.run(panel) == .OK, let url = panel.url else { return }

        do {
            let rows = try CSVImporter.parse(String(contentsOf: url, encoding: .utf8)).get()
            let imported = importRows(rows)
            let alert = NSAlert()
            alert.messageText = String(localized: "Imported \(imported) items, skipped \(rows.count - imported) duplicates or empty rows.")
            alert.runModal()
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = String(localized: "Failed to import CSV")
            alert.runModal()
        }
    }

    private func importRows(_ rows: [CSVExportRow]) -> Int {
        let now = Date()
        var imported = 0
        for row in rows where !row.text.isEmpty {
            let data = Data(row.text.utf8)
            let dataHash = SHA256.hash(data: data).description
            guard repository.getItem(hash: dataHash) == nil else { continue }

            let item = repository.create()
            item.rawString = row.text
            item.content = data
            item.name = row.name.isEmpty ? String(row.text.prefix(100)) : row.name
            item.binarySize = Int64(data.count)
            item.textLength = Int64(row.text.count)
            item.contentTypeString = NSPasteboard.PasteboardType.string.rawValue
            item.dataHash = dataHash
            item.favorite = row.isFavorite
            item.memo = row.memo
            item.updateDate = row.updateDate ?? now
            item.createdDate = row.createdDate ?? item.updateDate
            item.reminderDate = row.reminderDate
            imported += 1

            if let reminder = row.reminderDate, reminder > now {
                scheduleReminder(dataHash: dataHash, body: reminderBody(for: item), date: reminder, reportsFailure: false)
            }
        }
        repository.update()
        return imported
    }
}
