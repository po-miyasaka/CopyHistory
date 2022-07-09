//
//  CopyHistoryApp.swift
//  CopyHistory
//
//  Created by miyasaka on 2022/07/06.
//

import SwiftUI

struct CopyHistoryApp: App {
    
    @StateObject var pasteboardSevice: PasteboardService = .build()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 300, minHeight: 400)
                .environmentObject(pasteboardSevice)
        }
        
    }
}
