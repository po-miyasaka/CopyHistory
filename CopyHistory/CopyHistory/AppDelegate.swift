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
    private var statusBar: StatusBarController!

    func applicationDidFinishLaunching(_: Notification) {
        statusBar = .init()
    }

    func applicationDidBecomeActive(_: Notification) {
        statusBar.togglePopover(nil)
    }
}

private final class StatusBarController: NSObject, NSPopoverDelegate {
    var mainMenu: NSMenu?
    var popover: NSPopover?
    var statusBarItem: NSStatusItem?

    override init() {
        super.init()
        let image = NSImage(imageLiteralResourceName: "logo.svg")
        let popover = NSPopover()
        popover.contentSize = windowSize
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MainView { size in
            save(windowSize: size)
            popover.contentSize = size
        })
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

let widthKey = "windowSizeWidth"
let heightKey = "windowSizeHeight"
var windowSize: NSSize {
    let height = CGFloat(UserDefaults.standard.object(forKey: heightKey) as? CGFloat ?? NSScreen.main?.frame.height ?? 800)
    let width = CGFloat(UserDefaults.standard.object(forKey: widthKey) as? CGFloat ?? 500)
    return NSSize(width: width, height: height)
}

func save(windowSize size: NSSize = NSSize(width: 500, height: NSScreen.main?.frame.height ?? 800)) {
    UserDefaults.standard.set(size.height, forKey: heightKey)
    UserDefaults.standard.set(size.width, forKey: widthKey)
}

let versionString: String = {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    return "\(version ?? "") (\(build ?? ""))"
}()
