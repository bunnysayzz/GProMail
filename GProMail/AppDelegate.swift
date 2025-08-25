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
        // Set up window delegate first
        window.delegate = self
        
        // Ensure window is resizable and has proper constraints
        window.minSize = NSSize(width: 800, height: 600)
        window.isRestorable = true
        
        // Restore saved window frame BEFORE showing window
        restoreWindowFrame()
        
        // Make window visible
        window.makeKeyAndOrderFront(nil)
        
        print("App launched with window frame: \(NSStringFromRect(window.frame))")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            window.orderFront(self)
        } else {
            window.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Save frame before app terminates - very important!
        saveWindowFrame()
        print("🛑 App terminating - final frame save completed")
    }
    
    private func restoreWindowFrame() {
        // Use a consistent key for saving/loading window frame
        let frameKey = "GProMailWindowFrame"
        
        // Try to restore saved window frame from UserDefaults
        if let frameString = UserDefaults.standard.string(forKey: frameKey) {
            print("Found saved frame: \(frameString)")
            let frame = NSRectFromString(frameString)
            
            // Ensure the frame is valid and has reasonable dimensions
            if !frame.isEmpty && frame.size.width >= 800 && frame.size.height >= 600 {
                // Check if frame is within any available screen
                let screens = NSScreen.screens
                var frameIsVisible = false
                
                for screen in screens {
                    let visibleFrame = screen.visibleFrame
                    // Check if at least part of the window would be visible
                    if visibleFrame.intersects(frame) {
                        frameIsVisible = true
                        break
                    }
                }
                
                if frameIsVisible {
                    // Set the frame without animation for startup
                    window.setFrame(frame, display: false, animate: false)
                    print("✅ Window frame restored successfully: \(frameString)")
                    return
                } else {
                    print("⚠️ Saved frame is off-screen, using default position")
                }
            } else {
                print("⚠️ Invalid saved frame dimensions, using default")
            }
        } else {
            print("ℹ️ No saved window frame found, using default size")
        }
        
        // If we get here, use a sensible default frame
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let defaultWidth: CGFloat = 1200
            let defaultHeight: CGFloat = 800
            
            // Center the default window on the main screen
            let x = screenFrame.origin.x + (screenFrame.size.width - defaultWidth) / 2
            let y = screenFrame.origin.y + (screenFrame.size.height - defaultHeight) / 2
            
            let defaultFrame = NSRect(x: x, y: y, width: defaultWidth, height: defaultHeight)
            window.setFrame(defaultFrame, display: false, animate: false)
            print("🎯 Set default window frame: \(NSStringFromRect(defaultFrame))")
        }
    }
    
    private func saveWindowFrame() {
        // Use the same consistent key as restoreWindowFrame
        let frameKey = "GProMailWindowFrame"
        
        // Get current window frame
        let currentFrame = window.frame
        let frameString = NSStringFromRect(currentFrame)
        
        // Save to UserDefaults
        UserDefaults.standard.set(frameString, forKey: frameKey)
        UserDefaults.standard.synchronize() // Force immediate save
        
        print("💾 Window frame saved: \(frameString)")
        print("   Size: \(Int(currentFrame.width)) x \(Int(currentFrame.height))")
        print("   Position: (\(Int(currentFrame.origin.x)), \(Int(currentFrame.origin.y)))")
    }
}

// MARK: - NSWindowDelegate
extension AppDelegate: NSWindowDelegate {
    
    func windowDidResize(_ notification: Notification) {
        // Save frame after resize with small delay to ensure resize is complete
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(saveWindowFrameDelayed), object: nil)
        perform(#selector(saveWindowFrameDelayed), with: nil, afterDelay: 0.2)
    }
    
    func windowDidMove(_ notification: Notification) {
        // Save frame after move with small delay to ensure move is complete  
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(saveWindowFrameDelayed), object: nil)
        perform(#selector(saveWindowFrameDelayed), with: nil, afterDelay: 0.2)
    }
    
    func windowWillClose(_ notification: Notification) {
        // Save frame immediately before closing - no delay needed
        saveWindowFrame()
        print("🚪 Window closing - frame saved")
    }
    
    func windowDidEndLiveResize(_ notification: Notification) {
        // Save frame immediately after user finishes resizing
        saveWindowFrame()
        print("📏 Live resize ended - frame saved")
    }
    
    @objc private func saveWindowFrameDelayed() {
        saveWindowFrame()
    }
}