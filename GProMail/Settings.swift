//
//  Settings.swift
//  gInbox
//
//  Created by Chen Asraf on 11/9/14.
//  Copyright (c) 2014 Chen Asraf. All rights reserved.
//

import Foundation
import WebKit
import AppKit

public class Settings: NSWindowController, NSWindowDelegate {
    
    lazy var webViewController = WebViewController()
    var webView: WKWebView!
    
    public override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
    }
    
    public func showWindow(sender: Any?, webView: WKWebView) {
        super.showWindow(sender)
        self.webView = webView
    }
    
    public func windowWillClose(_ notification: Notification) {
        if let webUA = Preferences.getString(key: "userAgentString") {
            webView.customUserAgent = webUA
            webView.reload()
        }
    }
    
    @IBAction func resetPrefsToDefault(_ sender: Any?) {
        Preferences.clearDefaults()
    }
}