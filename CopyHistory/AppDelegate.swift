import Cocoa
import CryptoKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarItem.menu?.delegate = self
        latestChangeCount = pasteBoard.changeCount
        timer.fire()
    }
    
    @objc func timerLoop() {
        if pasteBoard.changeCount == latestChangeCount { return } // 変更がなければなにもしない
        latestChangeCount = pasteBoard.changeCount
        
        guard let newItem = pasteBoard.pasteboardItems?.first,
              let type = newItem.availableType(from: newItem.types),
              let data = newItem.data(forType: type) else { return }
        let dataHash = CryptoKit.SHA256.hash(data: data).description
        
        if let alreadySavedItem = getCopiedItem(from: dataHash) {
            // すでに存在している
            alreadySavedItem.updateDate = Date()
        } else {
            // 新しい
            let copiedItem = createCopiedItem()
            copiedItem.name = newItem.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines)
            copiedItem.content = data
            copiedItem.contentTypeString = type.rawValue
            copiedItem.updateDate = Date()
            copiedItem.dataHash = dataHash
        }
        
        persists()
    }
        
    @objc func didItemSelected(sender menuItem: NSMenuItem) {
        guard let copiedItem = menuItem.representedObject as? CopiedItem,
              let contentTypeString = copiedItem.contentTypeString,
              let contentData = copiedItem.content
        else { return }
        let type = NSPasteboard.PasteboardType(contentTypeString)
        let item = NSPasteboardItem()
        item.setData(contentData, forType: type)
        if let name = copiedItem.name {
            item.setString(name, forType: .string)
        }
        pasteBoard.declareTypes([type, .string], owner: nil)
        pasteBoard.writeObjects([item])
        
        copiedItem.updateDate = Date()
        persists()
    }
        
    func makeMenuItems(from copiedItems: [CopiedItem] ) -> [NSMenuItem] {
        copiedItems.map {
            let name = String(($0.name ?? "💾 data").prefix(30))
            let menuItem = NSMenuItem(title: name, action: #selector(didItemSelected), keyEquivalent: "")
            menuItem.representedObject = $0
            return menuItem
        }
    }

    func showMenuItems(with items: [CopiedItem]) {
        let searchField = NSSearchField.init(frame: .init(origin: .zero, size: .init(width: 300, height: 30)) )
        self.searchField = searchField
        searchField.delegate = self
        let searchMenuItem = NSMenuItem()
        searchMenuItem.view = searchField
        statusBarItem.menu?.removeAllItems()
        statusBarItem.menu?.addItem(searchMenuItem)
        makeMenuItems(from: items).forEach {
            statusBarItem.menu?.addItem($0)
        }
        statusBarItem.menu?.addItem(NSMenuItem.separator())
        statusBarItem.menu?.addItem(withTitle: "clear all items", action: #selector(clearAllItems), keyEquivalent: "")
        statusBarItem.menu?.addItem(withTitle: "quit", action: #selector(quit), keyEquivalent: "")
    }
    
    
    var viewContext: NSManagedObjectContext { persistentContainer.viewContext }
    var searchField: NSSearchField?
    var pasteBoard: NSPasteboard { NSPasteboard.general }
    var latestChangeCount = 0
    
    
    
    // pasteboradの変更検知はできないらしいためポーリングする。
    // https://stackoverflow.com/questions/5033266/can-i-receive-a-callback-whenever-an-nspasteboard-is-written-to
    lazy var timer: Timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerLoop), userInfo: nil, repeats: true)
    var statusBarItem: NSStatusItem = {
        let statusBar = NSStatusBar.system
        let statusBarItem = statusBar.statusItem(
            withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "📝"
        let menu: NSMenu = .init(title: "CopyHistory")
        statusBarItem.menu = menu
        return statusBarItem
    }()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { description, error in
            assert(error == nil, "conatiner not found")
        }
        return container
    }()
    
    @objc func quit() {
        abort()
    }
}

extension AppDelegate: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        showMenuItems(with: getSavedCopiedItems())
    }
    
    func menuDidClose(_ menu: NSMenu) {
        // menuを開くときにフォーカスが当てるために、activateしている。なぜか2回statusbarItemをクリックしないとforcusされない
        // https://www.mail-archive.com/search?l=cocoa-dev@lists.apple.com&q=subject:%22setting+focus+on+NSSearchField+in+status+bar+menu+item%22&o=newest&f=1
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: NSSearchFieldDelegate {
    func searchFieldDidStartSearching(_ sender: NSSearchField) {
        showMenuItems(with: getSavedCopiedItems(with: sender.stringValue))
    }
}

// MARK: - CRUD
extension AppDelegate {
    func createCopiedItem() -> CopiedItem {
        .init(context: viewContext)
    }
    
    func getSavedCopiedItems(with name: String? = nil) -> [CopiedItem] {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        var updateDateSort = SortDescriptor<CopiedItem>(\.updateDate)
        
        if let name = name, !name.isEmpty {
            let predicate = NSPredicate(format: "name CONTAINS %@", arguments: getVaList([name]))
            fetchRequest.predicate = predicate
        }
        
        updateDateSort.order = .reverse
        fetchRequest.sortDescriptors = [NSSortDescriptor(updateDateSort)]
        return (try? viewContext.fetch(fetchRequest)) ?? []
    }
    
    func getCopiedItem(from hash: String) -> CopiedItem? {
        let fetchRequest = NSFetchRequest<CopiedItem>(entityName: CopiedItem.className())
        let predicate = NSPredicate(format: "dataHash == %@", arguments: getVaList([hash]))
        fetchRequest.predicate = predicate
        return (try? viewContext.fetch(fetchRequest))?.first
    }
    
    @objc func clearAllItems() {
        let items = getSavedCopiedItems()
        items.forEach{
            viewContext.delete($0)
            
        }
        persists()
    }
    
    func persists() {
        try? viewContext.save()
    }
}
