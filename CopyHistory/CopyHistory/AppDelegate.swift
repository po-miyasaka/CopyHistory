//
//  AppDelegate.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/08.
//

import Cocoa
import SwiftUI

@main
struct MainApp: App {
#if os(macOS)
@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif
    var body: some Scene {
        WindowGroup {
            VStack{}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController<ContentView>!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = StatusBarController(
            ContentView(),
            width: 500,
            height: 600,
            image: NSImage(named: "scroll")!
        )
    }
}

private final class StatusBarController<Content: View> {
    private var mainMenu: NSMenu!
    private var popover: NSPopover!
    private var statusBarItem: NSStatusItem!
    
    init(_ view: Content, width: Int, height: Int, image: NSImage) {

        let nib = NSNib(nibNamed: "MainMenu", bundle: Bundle.main)!
        var topLevelArray: NSArray?
        nib.instantiate(withOwner: nil, topLevelObjects: &topLevelArray)
        let results = topLevelArray as! [Any]
        let item = results.last { $0 is NSMenu }
        mainMenu = item as? NSMenu
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: width, height: height)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
        
        // Create the status item
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = statusBarItem.button {
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}



