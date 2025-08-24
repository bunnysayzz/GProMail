//
//  AppDelegate.swift
//  gInbox
//
//  Created by Chen Asraf on 11/9/14.
//  Copyright (c) 2014 Chen Asraf. All rights reserved.
//

import Foundation
import Cocoa
import WebKit
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up window frame autosave
        window.setFrameAutosaveName("MainWindow")
        
        // Restore saved window frame if available
        restoreWindowFrame()
        
        // Set up window delegate to save frame on changes
        window.delegate = self
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            window.orderFront(self)
        } else {
            window.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    private func restoreWindowFrame() {
        // Try to restore saved window frame
        if let frameString = UserDefaults.standard.string(forKey: "MainWindowFrame") {
            let frame = NSRectFromString(frameString)
            if !frame.isEmpty {
                window.setFrame(frame, display: true)
            }
        }
    }
    
    private func saveWindowFrame() {
        // Save current window frame
        let frameString = NSStringFromRect(window.frame)
        UserDefaults.standard.set(frameString, forKey: "MainWindowFrame")
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    
    func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }
    
    func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }
    
    func windowWillClose(_ notification: Notification) {
        saveWindowFrame()
    }
}