//
//  WebViewController.swift
//  gInbox
//
//  Created by Chen Asraf on 11/11/14.
//  Copyright (c) 2014 Chen Asraf. All rights reserved.
//

import Foundation
import WebKit
import AppKit

class WebViewController: NSViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!
    let settingsController = Settings(windowNibName: NSNib.Name("Settings"))
    
    // constants
    let webUrl = "https://inbox.google.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.width, .height]
        view.addSubview(webView)
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Set up JavaScript injection
        injectConsoleLogging()
        
        if !Preferences.getBool(key: "afterFirstLaunch") {
            Preferences.clearDefaults()
        }
        
        // Use standard WebView settings
        let config = webView.configuration
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()
        
        // Use a simple Safari user agent that Google recognizes
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
        webView.customUserAgent = userAgent
        
        if let url = URL(string: webUrl) {
            let request = URLRequest(url: url)
            // Use minimal headers to avoid triggering Google's security checks
            webView.load(request)
            webView.load(request)
            
            // Add a small delay and then refresh to ensure proper loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.webView.reload()
            }
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
        settingsController.showWindow(sender: sender, webView: webView)
    }
    
    // MARK: - WKNavigationDelegate
    
    @MainActor
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @Sendable (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // Handle Google OAuth and Gmail URLs within the app
        if url.host?.contains("google.com") == true ||
           url.host?.contains("accounts.google.") == true ||
           url.host?.contains("mail.google.") == true ||
           url.host?.contains("inbox.google.") == true {
            decisionHandler(.allow)
            return
        }
        
        // Handle other http/https links
        if url.absoluteString.hasPrefix("http") {
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
            return
        }
        
        // Handle other URL schemes (mailto:, tel:, etc.)
        if url.scheme != nil && url.scheme != "about" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            NSWorkspace.shared.open(url)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let path = Bundle.main.path(forResource: "gInboxTweaks", ofType: "js", inDirectory: "Assets") {
            if let jsString = try? String(contentsOfFile: path, encoding: .utf8) {
                webView.evaluateJavaScript(jsString, completionHandler: nil)
                
                if let hangoutsMode = Preferences.getString(key: "hangoutsMode") {
                    let js = String(format: "console.log('test'); updateHangoutsMode(%@)", hangoutsMode)
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
            }
        }
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "consoleLog", let messageBody = message.body as? String {
            NSLog("[JS] -> %@", messageBody)
        }
    }
    
    // JavaScript console logging
    func injectConsoleLogging() {
        let consoleLogFunction = """
        console.log = function(message) {
            window.webkit.messageHandlers.consoleLog.postMessage(message);
        };
        """
        
        let userScript = WKUserScript(source: consoleLogFunction,
                                    injectionTime: .atDocumentStart,
                                    forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(self, name: "consoleLog")
    }
    
    // Inject custom JavaScript
    func injectCustomScripts() {
        if let path = Bundle.main.path(forResource: "gInboxTweaks", ofType: "js", inDirectory: "Assets") {
            do {
                let jsString = try String(contentsOfFile: path, encoding: .utf8)
                let userScript = WKUserScript(source: jsString,
                                            injectionTime: .atDocumentEnd,
                                            forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(userScript)
                
                if let hangoutsMode = Preferences.getString(key: "hangoutsMode") {
                    let hangoutsScript = "updateHangoutsMode(\(hangoutsMode));"
                    webView.evaluateJavaScript(hangoutsScript, completionHandler: nil)
                }
            } catch {
                print("Failed to load gInboxTweaks.js: \(error)")
            }
        }
    }
    
}