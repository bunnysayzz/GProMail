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
    var topBarView: TopBarView!
    let settingsController = Settings(windowNibName: NSNib.Name("Settings"))
    
    // constants
    let webUrl = "https://mail.google.com"
    let topBarHeight: CGFloat = 60
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTopBar()
        setupWebView()
        setupConstraints()
        
        if !Preferences.getBool(key: "afterFirstLaunch") {
            Preferences.clearDefaults()
        }
        
        configureWebView()
        loadGmail()
    }
    
    private func setupTopBar() {
        topBarView = TopBarView()
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBarView)
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // Add JavaScript message handler
        userContentController.add(self, name: "gInboxHandler")
        
        // Enhanced CSS to completely hide Gmail's title and change document title
        let cssString = """
        /* Only hide specific title text elements, preserve all functionality */
        [title*="Inbox for Gmail"] { visibility: hidden !important; }
        [aria-label*="Inbox for Gmail"] { visibility: hidden !important; }
        
        /* Hide only the "Inbox for Gmail" text in the title area */
        .gb_Mc .gb_Nc { visibility: hidden !important; }
        
        /* Hide only the Google Apps launcher (9-dot grid) - very targeted */
        a[aria-label*="Google apps"] { display: none !important; }
        
        /* Make main content take full space from top */
        .nH.nn { top: 0 !important; }
        .nH.aXjCH { top: 0 !important; }
        .nH.bkK { top: 0 !important; }
        .aAA { top: 0 !important; }
        """
        
        let cssScript = WKUserScript(source: """
        var style = document.createElement('style');
        style.textContent = `\(cssString)`;
        document.head.appendChild(style);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        userContentController.addUserScript(cssScript)
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view.addSubview(webView)
        
        // Connect webView to topBarView for refresh functionality
        topBarView.webView = webView
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Top bar constraints
            topBarView.topAnchor.constraint(equalTo: view.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: topBarHeight),
            
            // WebView constraints - positioned below top bar
            webView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureWebView() {
        // Use standard WebView settings
        let config = webView.configuration
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.websiteDataStore = .default()
        
        // Use a modern Safari user agent that Google recognizes
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
        webView.customUserAgent = userAgent
    }
    
    private func loadGmail() {
        if let url = URL(string: webUrl) {
            let request = URLRequest(url: url)
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
        
        // Handle all Google-related URLs within the app (including authentication)
        if url.host?.contains("google.com") == true ||
           url.host?.contains("accounts.google.") == true ||
           url.host?.contains("mail.google.") == true ||
           url.host?.contains("inbox.google.") == true ||
           url.host?.contains("gstatic.com") == true ||
           url.host?.contains("googleusercontent.com") == true ||
           url.host?.contains("googleapis.com") == true {
            decisionHandler(.allow)
            return
        }
        
        // Handle other http/https links - only open external if it's a user-initiated link click
        if url.absoluteString.hasPrefix("http") {
            if navigationAction.navigationType == .linkActivated {
                // Check if it's a Google-related URL that should stay in app
                if url.absoluteString.contains("google") || url.absoluteString.contains("accounts") {
                    decisionHandler(.allow)
                    return
                }
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
        // Handle new windows/popups within the app instead of external browser
        if let url = navigationAction.request.url {
            // Check if it's a Google-related URL (authentication, account management, etc.)
            if url.host?.contains("google.com") == true ||
               url.host?.contains("accounts.google.") == true ||
               url.host?.contains("mail.google.") == true ||
               url.absoluteString.contains("oauth") ||
               url.absoluteString.contains("signin") ||
               url.absoluteString.contains("accounts") {
                
                // Load the URL in the existing webview instead of opening externally
                let request = URLRequest(url: url)
                webView.load(request)
                return nil
            }
            
            // For non-Google URLs, open externally
            NSWorkspace.shared.open(url)
        }
        return nil
    }
    
    @MainActor
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("Page finished loading")
        
        // Set the window title to our custom title
        if let window = view.window {
            window.title = "GProMail for Gmail"
        }
        
        // Inject our custom JavaScript to ensure title stays correct
        let titleScript = """
        document.title = 'GProMail for Gmail';
        
        // Override any future title changes
        Object.defineProperty(document, 'title', {
            set: function(newTitle) {
                if (newTitle !== 'GProMail for Gmail') {
                    document.getElementsByTagName('title')[0].innerHTML = 'GProMail for Gmail';
                }
            },
            get: function() {
                return 'GProMail for Gmail';
            }
        });
        """
        
        webView.evaluateJavaScript(titleScript) { result, error in
            if let error = error {
                NSLog("Error setting title: \(error)")
            }
        }
        
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