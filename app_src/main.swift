//
//  main.swift
//  bengal
//
//  Created by naomisphere on April 7th, 2026.
//  Copyright © 2026 naomisphere. All rights reserved.
//

import Cocoa

class b_app_delegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var mainView: wrapper_app_ui!

    func applicationDidFinishLaunching(_ notification: Notification) {
        BengalFont.registerAll()
        
        let mask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1100, height: 600),
                         styleMask: mask,
                         backing: .buffered,
                         defer: false)
        
        window.center()
        window.title = "bengal"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = BengalStyle.background
        window.isMovableByWindowBackground = false
        
        mainView = wrapper_app_ui(frame: window.contentView!.bounds)
        window.contentView?.addSubview(mainView)
        mainView.autoresizingMask = [.width, .height]
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = b_app_delegate()
app.delegate = delegate
app.run()
