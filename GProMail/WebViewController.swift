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
        
        /* Hide support/help icon beside search bar */
        [aria-label*="Support"] { display: none !important; }
        [aria-label*="Help"] { display: none !important; }
        [aria-label*="support"] { display: none !important; }
        [aria-label*="help"] { display: none !important; }
        [data-tooltip*="Support"] { display: none !important; }
        [data-tooltip*="Help"] { display: none !important; }
        .gb_Pc { display: none !important; }
        .gb_Qc { display: none !important; }
        .gb_Rc { display: none !important; }
        [role="button"][aria-label*="Support"] { display: none !important; }
        [role="button"][aria-label*="Help"] { display: none !important; }
        
        /* Hide Gmail's right side panel (chat/hangouts) and its toggle button */
        .bHp { display: none !important; }
        .bHO { display: none !important; }
        .aAz { display: none !important; }
        .aKr { display: none !important; }
        .aKs { display: none !important; }
        [data-tooltip*="Hide side panel"] { display: none !important; }
        [data-tooltip*="Show side panel"] { display: none !important; }
        [aria-label*="Show side panel"] { display: none !important; }
        [aria-label*="Hide side panel"] { display: none !important; }
        [aria-label*="Chat"] { display: none !important; }
        [aria-label*="Hangouts"] { display: none !important; }
        div[role="complementary"] { display: none !important; }
        .aKQ { display: none !important; }
        .aKT { display: none !important; }
        .bAw { display: none !important; }
        
        /* Disable profile picture editing within account panel while preserving account switching */
        /* Hide camera icon and profile picture edit functionality */
        [aria-label*="Change profile picture"] { display: none !important; }
        [aria-label*="Edit profile picture"] { display: none !important; }
        [aria-label*="Update profile picture"] { display: none !important; }
        [data-tooltip*="Change profile picture"] { display: none !important; }
        [data-tooltip*="Edit profile picture"] { display: none !important; }
        
        /* Hide camera overlay on profile picture */
        .gb_Aa .gb_Ba { display: none !important; }
        .gb_Ca .gb_Ba { display: none !important; }
        .gb_Da .gb_Ba { display: none !important; }
        
        /* Keep account panel clickable - DO NOT disable profile picture clicking for account switching */
        /* Only disable editing-specific elements within the panel */
        
        /* Hide any camera icons in account menu */
        [data-value="camera"] { display: none !important; }
        [aria-label*="camera"] { display: none !important; }
        .gb_kb { display: none !important; } /* Camera icon class */
        .gb_lb { display: none !important; } /* Camera icon class */
        
        /* Prevent profile picture edit dialog from opening */
        [role="dialog"][aria-label*="profile"] { display: none !important; }
        [role="dialog"][aria-label*="photo"] { display: none !important; }
        
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
        
        // Disable right-click and developer tools keyboard shortcuts
        let disableInspectScript = WKUserScript(source: """
        // Disable right-click context menu
        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
            return false;
        }, true);
        
        // Disable common developer tools keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            // Disable F12, Cmd+Option+I, Cmd+Option+J, Cmd+Option+C, Cmd+Shift+I
            if (e.keyCode === 123 || // F12
                (e.metaKey && e.altKey && e.keyCode === 73) || // Cmd+Option+I
                (e.metaKey && e.altKey && e.keyCode === 74) || // Cmd+Option+J
                (e.metaKey && e.altKey && e.keyCode === 67) || // Cmd+Option+C
                (e.metaKey && e.shiftKey && e.keyCode === 73)) { // Cmd+Shift+I
                e.preventDefault();
                return false;
            }
        }, true);
        
        // Disable text selection for a more app-like feel (optional)
        document.addEventListener('selectstart', function(e) {
            if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                e.preventDefault();
                return false;
            }
        }, true);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        // Disable account management links while preserving account switching
        let disableAccountManagementScript = WKUserScript(source: """
        // Function to disable specific account management links
        function disableAccountManagementLinks() {
            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', disableAccountManagementLinks);
                return;
            }
            
            // Disable clicks on account management elements
            document.addEventListener('click', function(e) {
                var target = e.target;
                var text = target.textContent || target.innerText || '';
                var href = target.href || '';
                var ariaLabel = target.getAttribute('aria-label') || '';
                
                // Check if this is a management/policy link we want to disable
                if (
                    // Manage Google Account button
                    text.includes('Manage your Google Account') ||
                    text.includes('Manage account') ||
                    href.includes('myaccount.google.com') ||
                    ariaLabel.includes('Manage your Google Account') ||
                    
                    // Manage storage link
                    text.includes('Manage storage') ||
                    text.includes('Storage') ||
                    href.includes('storage') ||
                    
                    // Privacy policy link
                    text.includes('Privacy policy') ||
                    text.includes('Privacy') ||
                    href.includes('privacy') ||
                    
                    // Terms of service link
                    text.includes('Terms of Service') ||
                    text.includes('Terms') ||
                    href.includes('terms') ||
                    
                    // Profile picture editing functionality
                    text.includes('Change profile picture') ||
                    text.includes('Edit profile picture') ||
                    text.includes('Update profile picture') ||
                    text.includes('Camera') ||
                    ariaLabel.includes('Change profile picture') ||
                    ariaLabel.includes('Edit profile picture') ||
                    ariaLabel.includes('Update profile picture') ||
                    ariaLabel.includes('camera') ||
                    target.closest('[data-value="camera"]') ||
                    target.classList.contains('gb_kb') ||
                    target.classList.contains('gb_lb')
                ) {
                    e.preventDefault();
                    e.stopPropagation();
                    console.log('Blocked click on:', text || href || ariaLabel);
                    return false;
                }
            }, true);
            
            // Also disable these links via CSS pointer-events for extra safety
            var style = document.createElement('style');
            style.textContent = `
                [href*="myaccount.google.com"] { pointer-events: none !important; opacity: 0.6 !important; }
                [href*="storage"] { pointer-events: none !important; opacity: 0.6 !important; }
                [href*="privacy"] { pointer-events: none !important; opacity: 0.6 !important; }
                [href*="terms"] { pointer-events: none !important; opacity: 0.6 !important; }
                [aria-label*="Manage your Google Account"] { pointer-events: none !important; opacity: 0.6 !important; }
                button:has-text("Manage your Google Account") { pointer-events: none !important; opacity: 0.6 !important; }
                *[role="button"]:has-text("Manage storage") { pointer-events: none !important; opacity: 0.6 !important; }
            `;
            document.head.appendChild(style);
        }
        
        // Function to specifically disable profile picture editing elements within the account panel
        function disableProfilePictureEditing() {
            // Only disable camera icons and edit buttons within account panels, NOT the main profile picture
            var profileEditElements = document.querySelectorAll([
                '[aria-label*="Change profile picture"]',
                '[aria-label*="Edit profile picture"]', 
                '[aria-label*="camera"]',
                '[data-value="camera"]',
                '.gb_kb',
                '.gb_lb'
            ].join(','));
            
            profileEditElements.forEach(function(element) {
                element.style.pointerEvents = 'none';
                element.style.opacity = '0.6';
                element.setAttribute('disabled', 'true');
            });
            
            // DO NOT disable the main profile picture - it should open account panel
            // Only disable editing-specific elements within the panel
        }
        
        // Run the functions
        disableAccountManagementLinks();
        disableProfilePictureEditing();
        
        // Also run when new content is loaded (for dynamic content)
        var observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.addedNodes.length > 0) {
                    disableAccountManagementLinks();
                    disableProfilePictureEditing();
                }
            });
        });
        observer.observe(document.body, { childList: true, subtree: true });
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        userContentController.addUserScript(cssScript)
        userContentController.addUserScript(disableInspectScript)
        userContentController.addUserScript(disableAccountManagementScript)
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
        
        let urlString = url.absoluteString
        print("Navigation to: \(urlString)")
        
        // Always handle Gmail core URLs within the app
        let gmailCorePatterns = [
            "mail.google.com/mail/",
            "mail.google.com/u/",
            "accounts.google.com/signin",
            "accounts.google.com/oauth",
            "accounts.google.com/AddSession",
            "accounts.google.com/logout",
            "accounts.google.com/b/0/AddSession"
        ]
        
        for pattern in gmailCorePatterns {
            if urlString.contains(pattern) {
                print("Gmail core navigation - staying in app")
                decisionHandler(.allow)
                return
            }
        }
        
        // Handle Google static resources and APIs within the app
        if url.host?.contains("gstatic.com") == true ||
           url.host?.contains("googleusercontent.com") == true ||
           url.host?.contains("googleapis.com") == true ||
           url.host?.contains("google.com") == true && urlString.contains("/gen_") {
            decisionHandler(.allow)
            return
        }
        
        // Check for external links that should open in browser
        if navigationAction.navigationType == .linkActivated {
            // Gmail redirect URLs (these are external links from emails)
            if urlString.contains("www.google.com/url?") ||
               urlString.contains("gmail.com/u/0/l/") ||
               urlString.contains("mail.google.com/mail/u/0/l/") {
                print("Gmail redirect link - opening in browser")
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            
            // Direct external links (not Google domains)
            if !(url.host?.contains("google.com") == true) &&
               !(url.host?.contains("googleusercontent.com") == true) &&
               !(url.host?.contains("googleapis.com") == true) &&
               !(url.host?.contains("gstatic.com") == true) {
                print("External link - opening in browser: \(url.host ?? "unknown")")
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        
        // Handle other URL schemes (mailto:, tel:, etc.)
        if let scheme = url.scheme,
           scheme != "http" && scheme != "https" && scheme != "about" {
            print("Special URL scheme - opening externally: \(scheme)")
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        // Default: allow navigation within the app
        print("Allowing navigation within app")
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
    
    // Disable context menu (inspect element) - compatible with macOS 10.15+
    @available(macOS 10.15, *)
    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: [String : Any]) -> NSMenu? {
        // Return nil to disable context menu completely
        return nil
    }
    
    // Disable context menu using WKUIDelegate method
    func webView(_ webView: WKWebView, runContextMenu menu: NSMenu, for element: [String : Any], in frame: CGRect) {
        // Don't show context menu by not calling anything
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