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
    private var pasteBoard: NSPasteboard { NSPasteboard.general }
    private(set) var latestChangeCount = 0
    private lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    
    private var createCopiedItem: (() -> CopiedItem?)
    private var getItem: ((String) -> CopiedItem?)
    private var saveItem: (() -> Void)
    
    private init(createCopiedItem: @escaping () -> CopiedItem?,
                 getItem: @escaping (String) -> CopiedItem?,
                 saveItem: @escaping () -> Void) {
        self.createCopiedItem = createCopiedItem
        self.getItem = getItem
        self.saveItem = saveItem
    }
    
    static func build(
        createCopiedItem: @escaping () -> CopiedItem?,
        getItem: @escaping (String) -> CopiedItem?,
        saveItem: @escaping () -> Void) -> PasteboardService {
            let pasteboardService = PasteboardService(
                createCopiedItem: createCopiedItem,
                getItem: getItem,
                saveItem: saveItem)
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
    
    
    @objc func timerLoop() {
        Task {
            if pasteBoard.changeCount == latestChangeCount { return } // If there is no change, do nothing.
            
            defer { // TODO: when is it called
                latestChangeCount = pasteBoard.changeCount
            }
            
            guard let newItem = pasteBoard.pasteboardItems?.first,
                  let type = newItem.availableType(from: newItem.types),
                  let data = newItem.data(forType: type),
                  pasteBoard.types?.contains(where: { $0.rawValue.contains("com.agilebits.onepassword") }) == false else { return }
            
            let dataHash = CryptoKit.SHA256.hash(data: data).description
            
            if let alreadySavedItem = getItem(dataHash) {
                // Existing
                alreadySavedItem.updateDate = Date()
            } else {
                // New
                if let copiedItem = createCopiedItem() {
                    let str = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    copiedItem.rawString = str
                    copiedItem.content = data
                    
                    copiedItem.name = String((str ?? "No Name").prefix(100))
                    copiedItem.binarySize = Int64(data.count)
                    copiedItem.contentTypeString = type.rawValue
                    copiedItem.updateDate = Date()
                    copiedItem.dataHash = dataHash
                }
            }
            saveItem()
        }
    }
    
}


