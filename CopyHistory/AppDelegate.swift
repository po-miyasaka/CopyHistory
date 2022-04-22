//
//  AppDelegate.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/04/22.
//

import Cocoa
import CryptoKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let popover = NSPopover()
    var menu: NSMenu = .init(title: "CopyHistory")
    lazy var statusBarItem: NSStatusItem = {
        let statusBar = NSStatusBar.system
        let statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "📝"
        statusBarItem.menu = menu
        return statusBarItem
    }()
    
    var pasteBoard: NSPasteboard { NSPasteboard.general }
    var latestChangeCount = 0
    lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(saveItem), userInfo: nil, repeats: true)
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { description, error in
            assert(error == nil, "conatiner not found")
        }
        return container
    }()
    
    var searchText: String?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem.menu?.delegate = self
        latestChangeCount = pasteBoard.changeCount
        timer.fire()
    }
    
    @objc func saveItem() {
        if pasteBoard.changeCount == latestChangeCount { return }
        latestChangeCount = pasteBoard.changeCount
        guard let newItem = pasteBoard.pasteboardItems?.first,
              let type = newItem.availableType(from: newItem.types),
              let data = newItem.data(forType: type) else { return }
        let hash = CryptoKit.SHA256.hash(data: data)
        let copiedItem = CopiedItem(context: persistentContainer.viewContext)
        
        if let alreadySavedItem =  getCopiedItem(from: hash.description) {
            alreadySavedItem.updateDate = Date()
            try? persistentContainer.viewContext.save()
            return
        }
        
        copiedItem.name = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
        copiedItem.content = data
        copiedItem.contentTypeString = type.rawValue
        copiedItem.updateDate = Date()
        copiedItem.dataHash = hash.description
        
        try? persistentContainer.viewContext.save()
    }
    
    @objc func didItemSelected(sender: Any) {
        guard let menuItem = sender as? NSMenuItem,
              let copiedData = menuItem.representedObject as? CopiedItem,
              let contentTypeString = copiedData.contentTypeString,
              let contentData = copiedData.content,
              let name = copiedData.name
        else { return }
        
        let type = NSPasteboard.PasteboardType(contentTypeString)
        let item = NSPasteboardItem()
        item.setData(contentData, forType: type)
        item.setString(name, forType: .string)
        pasteBoard.declareTypes([type, .string], owner: nil)
        pasteBoard.writeObjects([item])
    }
    
    func getSavedCopiedItems(with name: String? = nil) -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        
        if let name = name, !name.isEmpty {
            let predicate = NSPredicate.init(format: "name CONTAINS %@", arguments: getVaList([name]))
            fetchRequest.predicate = predicate
        }
        
        updateDateSort.order = .reverse
        fetchRequest.sortDescriptors = [NSSortDescriptor(updateDateSort)]
        return (try? persistentContainer.viewContext.fetch(fetchRequest)) ?? []
    }
    
    func getCopiedItem(from hash: String) -> CopiedItem? {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let predicate = NSPredicate.init(format: "dataHash == %@", arguments: getVaList([hash]))
        fetchRequest.predicate = predicate
        return (try? persistentContainer.viewContext.fetch(fetchRequest))?.first
    }
    
    func makeMenuItems(from copiedItems: [CopiedItem] ) -> [NSMenuItem]{
        copiedItems.map {
            let name = String(($0.name ?? "no name").prefix(30))
            let menuItem = NSMenuItem(title: name, action: #selector(didItemSelected), keyEquivalent: "")
            menuItem.representedObject = $0
            return menuItem
        }
    }
    
    func updateMenuItems(with items: [CopiedItem]) {
        menu.items = makeMenuItems(from: items)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "clear all items", action: #selector(clearAllItems), keyEquivalent: "")
    }
    
    @objc func clearAllItems() {
        getSavedCopiedItems().forEach{ persistentContainer.viewContext.delete($0) }
        try? persistentContainer.viewContext.save()
    }

}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuItems(with: getSavedCopiedItems(with: searchText))
    }
}
