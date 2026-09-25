//
//  AppDelegate.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/08.
//

import Cocoa
import SwiftUI
import UserNotifications

@main
struct MainApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {}
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var statusBar: StatusBarController?

    func applicationDidFinishLaunching(_: Notification) {
        UNUserNotificationCenter.current().delegate = self
        statusBar = .init()
        disableUnneededWindow()
        registerGlobalShortcut()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    private func registerGlobalShortcut() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let requiredFlags: NSEvent.ModifierFlags = [.command, .control, .option]
        guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(requiredFlags),
              event.charactersIgnoringModifiers == "4"
        else { return false }

        saveClipboardImageToDesktop()
        return true
    }

    private func saveClipboardImageToDesktop() {
        let pasteboard = NSPasteboard.general

        guard let image = NSImage(pasteboard: pasteboard) else {
            NSSound.beep()
            return
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:])
        else {
            NSSound.beep()
            return
        }

        let fileName = UUID().uuidString + ".png"
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            NSSound.beep()
            return
        }
        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
        } catch {
            NSSound.beep()
            return
        }

        PasteboardService.skipNextPasteboardChange = true
        pasteboard.clearContents()
        pasteboard.setString(fileURL.path, forType: .string)
    }

    func applicationDidBecomeActive(_: Notification) {
        disableUnneededWindow()
        if statusBar?.popover?.isShown == false {
            // コマンドで起動したときに起動するための処理
            // SONOMAより前はStatusBarのボタンを押してもDidBecameActiveは呼ばれなかった。
            statusBar?.show()
        }

    }

    func disableUnneededWindow() {
        NSApp.windows.filter { window in window.className == "SwiftUI.AppKitWindow" }.forEach { $0.setIsVisible(false) }
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
        popover.contentViewController = NSHostingController(rootView: MainView())
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

    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover?.isShown == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if let button = statusBarItem?.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func hide() {
        popover?.performClose(nil)
    }

    func popoverWillShow(_: Notification) {
        NSApplication.shared.unhide(nil)
    }

    func popoverDidClose(_: Notification) {
        NSApplication.shared.hide(nil) // this code make previous app activate back.

    }

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        true
    }

}

let widthKey = "windowSizeWidth"
let heightKey = "windowSizeHeight"
var windowSize: NSSize {
    //    let height = CGFloat(UserDefaults.standard.object(forKey: heightKey) as? CGFloat ?? NSScreen.main?.frame.height ?? 800)
    //    let width = CGFloat(UserDefaults.standard.object(forKey: widthKey) as? CGFloat ?? 500)
    let height =  CGFloat(NSScreen.main?.frame.height ?? 800)
    let width = CGFloat(500)
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
