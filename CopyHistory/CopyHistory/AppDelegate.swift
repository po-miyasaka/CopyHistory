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
            VStack {}
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController<ContentView>!

    func applicationDidFinishLaunching(_: Notification) {
        statusBar = .init(
            ContentView(),
            width: 500,
            height: NSScreen.main?.frame.height ?? 800.0,
            image: NSImage(imageLiteralResourceName: "logo")
        )
    }

    func applicationDidBecomeActive(_: Notification) {
        statusBar.togglePopover(nil)
    }
}

private final class StatusBarController<Content: View>: NSObject, NSPopoverDelegate {
    var mainMenu: NSMenu?
    var popover: NSPopover?
    var statusBarItem: NSStatusItem?

    init(_: Content, width: CGFloat, height: CGFloat, image: NSImage) {
        super.init()
        let popover = NSPopover()
        popover.contentSize = NSSize(width: width, height: height)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
        self.popover = popover
        statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        popover.delegate = self
        image.size = CGSize(width: 18, height: 18)
        image.backgroundColor = .white
        if let button = statusBarItem?.button {
            button.image = image
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        NSApp.windows.filter { window in window.className == "SwiftUI.AppKitWindow" }.forEach { $0.close() }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)

            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func popoverWillShow(_: Notification) {
        NSApplication.shared.unhide(nil)
    }

    func popoverDidClose(_: Notification) {
        NSApplication.shared.hide(nil) // this code make previous app activate back.
    }
}
