//
//  Persistence.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import Cocoa
import CoreData
import CryptoKit
import SwiftUI
import Combine

class PasteboardService {
    static var skipNextPasteboardChange = false
    private var pasteBoard: NSPasteboard { NSPasteboard.general }
    private(set) var latestChangeCount = 0
    private lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    private let pasteboardQueue = DispatchQueue(label: "jp.po-miyasaka.CopyHistory.pasteboard", qos: .utility)
    private var isPolling = false
    /// How long a single read may run before we tell the UI it is taking unusually long (a slow Handoff/simulator clipboard hand-off, for example).
    private static let slowReadThreshold: TimeInterval = 5.0

    private var createCopiedItem: (() -> CopiedItem?)
    private var getItem: ((String) -> CopiedItem?)
    private var saveItem: (() -> Void)
    private var didCreateItem: ((CopiedItem) -> Void)
    private var onSlowReadChanged: ((Bool) -> Void)

    private struct PasteboardSnapshot {
        let data: Data
        let dataHash: String
        let rawString: String?
        let contentTypeString: String
        let binarySize: Int64
        let textLength: Int64
        let name: String
    }

    private enum PasteboardPollResult {
        case noChange(Int)
        case changedWithoutUsableItem(Int)
        case snapshot(Int, PasteboardSnapshot)
    }

    private init(createCopiedItem: @escaping () -> CopiedItem?,
                 getItem: @escaping (String) -> CopiedItem?,
                 saveItem: @escaping () -> Void,
                 didCreateItem: @escaping (CopiedItem) -> Void,
                 onSlowReadChanged: @escaping (Bool) -> Void) {
        self.createCopiedItem = createCopiedItem
        self.getItem = getItem
        self.saveItem = saveItem
        self.didCreateItem = didCreateItem
        self.onSlowReadChanged = onSlowReadChanged
    }

    static func build(
        createCopiedItem: @escaping () -> CopiedItem?,
        getItem: @escaping (String) -> CopiedItem?,
        saveItem: @escaping () -> Void,
        didCreateItem: @escaping (CopiedItem) -> Void = { _ in },
        onSlowReadChanged: @escaping (Bool) -> Void = { _ in }) -> PasteboardService {
            let pasteboardService = PasteboardService(
                createCopiedItem: createCopiedItem,
                getItem: getItem,
                saveItem: saveItem,
                didCreateItem: didCreateItem,
                onSlowReadChanged: onSlowReadChanged)
            pasteboardService.timer.fire()
            return pasteboardService
        }

    func apply(_ copiedItem: CopiedItem, beforeContent: String = "", afterContent: String = "") {
        guard let contentTypeString = copiedItem.contentTypeString,
              let data = copiedItem.content
        else { return }
        let type = NSPasteboard.PasteboardType(contentTypeString)
        let item = NSPasteboardItem()
        item.setData(data, forType: type)
        if let rawString = copiedItem.rawString {
            item.setString(rawString, forType: .string)
        }
        pasteBoard.declareTypes([type, .string], owner: nil)
        pasteBoard.writeObjects([item])
    }

    func applyTransformed(_ text: String) {
        let item = NSPasteboardItem()
        item.setString(text, forType: .string)
        pasteBoard.declareTypes([.string], owner: nil)
        pasteBoard.writeObjects([item])
    }

    @objc func timerLoop() {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isPolling else { return }
            self.isPolling = true
            let previousChangeCount = self.latestChangeCount
            let skipsChange = Self.skipNextPasteboardChange
            if skipsChange {
                Self.skipNextPasteboardChange = false
            }

            // Flips to true only if the read is still running after `slowReadThreshold`; both closures below run on
            // the main queue, so this shared box needs no extra synchronization.
            var didNotifySlowRead = false
            let slowReadNotice = DispatchWorkItem { [weak self] in
                didNotifySlowRead = true
                self?.onSlowReadChanged(true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.slowReadThreshold, execute: slowReadNotice)

            pasteboardQueue.async { [weak self] in
                let result = Self.readPasteboard(previousChangeCount: previousChangeCount, skipsChange: skipsChange)
                DispatchQueue.main.async { [weak self] in
                    slowReadNotice.cancel()
                    if didNotifySlowRead { self?.onSlowReadChanged(false) }
                    self?.isPolling = false
                    self?.apply(result)
                }
            }
        }
    }

    private static func readPasteboard(previousChangeCount: Int, skipsChange: Bool) -> PasteboardPollResult {
        let pasteBoard = NSPasteboard.general
        let changeCount = pasteBoard.changeCount
        guard changeCount != previousChangeCount else { return .noChange(changeCount) }
        guard !skipsChange else { return .changedWithoutUsableItem(changeCount) }
        guard pasteBoard.types?.contains(where: { $0.rawValue.contains("com.agilebits.onepassword") }) == false,
              let newItem = pasteBoard.pasteboardItems?.first,
              let type = newItem.availableType(from: newItem.types),
              let data = newItem.data(forType: type) else {
            return .changedWithoutUsableItem(changeCount)
        }

        let rawString = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let snapshot = PasteboardSnapshot(
            data: data,
            dataHash: CryptoKit.SHA256.hash(data: data).description,
            rawString: rawString,
            contentTypeString: type.rawValue,
            binarySize: Int64(data.count),
            textLength: Int64(rawString?.count ?? 0),
            name: String((rawString ?? "No Name").prefix(100))
        )
        return .snapshot(changeCount, snapshot)
    }

    private func apply(_ result: PasteboardPollResult) {
        switch result {
        case .noChange(let changeCount),
             .changedWithoutUsableItem(let changeCount):
            latestChangeCount = changeCount
        case .snapshot(let changeCount, let snapshot):
            latestChangeCount = changeCount
            var createdItem: CopiedItem?

            if let alreadySavedItem = getItem(snapshot.dataHash) {
                // Existing
                alreadySavedItem.updateDate = Date()
            } else {
                // New
                if let copiedItem = createCopiedItem() {
                    copiedItem.rawString = snapshot.rawString
                    copiedItem.content = snapshot.data

                    copiedItem.name = snapshot.name
                    copiedItem.binarySize = snapshot.binarySize
                    copiedItem.textLength = snapshot.textLength
                    copiedItem.contentTypeString = snapshot.contentTypeString
                    let now = Date()
                    copiedItem.createdDate = now
                    copiedItem.updateDate = now
                    copiedItem.dataHash = snapshot.dataHash
                    createdItem = copiedItem
                }
            }
            saveItem()
            if let createdItem { didCreateItem(createdItem) }
        }
    }

}
