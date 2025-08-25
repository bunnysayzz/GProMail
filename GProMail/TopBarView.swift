//
//  TopBarView.swift
//  GProMail
//
//  Beautiful macOS-style top bar with app branding
//

import Cocoa
import WebKit

class TopBarView: NSView {
    
    private var titleLabel: NSTextField!
    private var appIconView: NSImageView!
    private var homeButton: NSView!
    private var homeButtonBackground: NSView!
    private var trackingArea: NSTrackingArea?
    private var isNavigating: Bool = false
    private var settingsButton: NSButton!
    private var refreshButton: NSButton!
    private var githubButton: NSButton!
    private var gradientLayer: CAGradientLayer?
    weak var webView: WKWebView?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        
        setupGradient()
        setupHomeButton()
        setupSettingsButton()
        setupRefreshButton()
        setupGitHubButton()
        setupConstraints()
    }
    
    override func layout() {
        super.layout()
        gradientLayer?.frame = bounds
    }
    
    private func setupGradient() {
        // Create gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor.controlBackgroundColor.withAlphaComponent(0.95).cgColor,
            NSColor.controlBackgroundColor.withAlphaComponent(0.85).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        layer?.addSublayer(gradient)
        gradientLayer = gradient
    }
    
    private func setupHomeButton() {
        homeButtonBackground = NSView()
        homeButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        homeButtonBackground.wantsLayer = true
        homeButtonBackground.layer?.backgroundColor = NSColor.clear.cgColor
        
        // Get the app icon from the bundle
        if let appIcon = NSApp.applicationIconImage {
            appIconView = NSImageView()
            appIconView.translatesAutoresizingMaskIntoConstraints = false
            appIconView.image = appIcon
            appIconView.imageScaling = .scaleProportionallyUpOrDown
            homeButtonBackground.addSubview(appIconView)
        } else {
            // Fallback to bundle icon
            appIconView = NSImageView()
            appIconView.translatesAutoresizingMaskIntoConstraints = false
            appIconView.image = NSImage(named: "AppIcon")
            appIconView.imageScaling = .scaleProportionallyUpOrDown
            homeButtonBackground.addSubview(appIconView)
        }
        
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = "GProMail"
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        homeButtonBackground.addSubview(titleLabel)
        
        homeButton = NSView()
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        homeButton.wantsLayer = true
        homeButton.layer?.backgroundColor = NSColor.clear.cgColor
        homeButton.addSubview(homeButtonBackground)
        addSubview(homeButton)
        
        // Set up premium styling for home button
        setupHomeButtonStyling()
        setupHomeButtonTracking()
    }
    
    private func setupHomeButtonStyling() {
        // Premium rounded button styling
        homeButton.wantsLayer = true
        homeButton.layer?.cornerRadius = 8
        homeButton.layer?.masksToBounds = true
        
        // Subtle background with transparency
        homeButtonBackground.wantsLayer = true
        homeButtonBackground.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1).cgColor
        homeButtonBackground.layer?.cornerRadius = 6
        homeButtonBackground.layer?.masksToBounds = true
        
        // Add subtle border
        homeButtonBackground.layer?.borderWidth = 0.5
        homeButtonBackground.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
    }
    
    private func setupHomeButtonTracking() {
        // Remove existing tracking area if any
        if let existingTrackingArea = trackingArea {
            homeButton.removeTrackingArea(existingTrackingArea)
        }
        
        // Create new tracking area for hover effects
        trackingArea = NSTrackingArea(
            rect: homeButton.bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        homeButton.addTrackingArea(trackingArea!)
        
        // Add click gesture recognizer
        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(homeButtonClicked))
        homeButton.addGestureRecognizer(clickRecognizer)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        
        // Smooth hover animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            
            // Premium hover effect with subtle shadow and background
            homeButtonBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
            homeButtonBackground.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
            homeButtonBackground.layer?.shadowOpacity = 0.1
            homeButtonBackground.layer?.shadowOffset = CGSize(width: 0, height: 1)
            homeButtonBackground.layer?.shadowRadius = 2
            homeButtonBackground.layer?.shadowColor = NSColor.black.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
        // Smooth exit animation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.allowsImplicitAnimation = true
            
            // Return to normal state
            homeButtonBackground.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1).cgColor
            homeButtonBackground.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
            homeButtonBackground.layer?.shadowOpacity = 0
        }
    }
    
    @objc private func homeButtonClicked() {
        // Prevent multiple rapid clicks
        guard !isNavigating else {
            print("🏠 Navigation already in progress...")
            return
        }
        
        isNavigating = true
        
        // Immediate visual feedback - show button is pressed
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.05
            context.allowsImplicitAnimation = true
            
            // Immediate feedback: darken button and scale down
            homeButtonBackground.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3).cgColor
            homeButtonBackground.layer?.transform = CATransform3DMakeScale(0.92, 0.92, 1.0)
        }
        
        // Navigate to Gmail home/inbox
        if let webView = webView {
            let homeURL = "https://mail.google.com/mail/u/0/#inbox"
            if let url = URL(string: homeURL) {
                let request = URLRequest(url: url)
                webView.load(request)
                print("🏠 Navigating to Gmail home: \(homeURL)")
            }
        }
        
        // Reset visual state and enable clicking again after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.allowsImplicitAnimation = true
                
                // Return to normal scale and color
                self.homeButtonBackground.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.1).cgColor
                self.homeButtonBackground.layer?.transform = CATransform3DIdentity
            }
        }
        
        // Allow clicking again after reasonable delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isNavigating = false
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupHomeButtonTracking()
    }
    
    private func setupSettingsButton() {
        settingsButton = NSButton()
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.isBordered = false
        settingsButton.bezelStyle = .inline
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)
        
        // Use user's exact settings SVG
        let settingsImage = createImageFromUserSVG(userSettingsSVG())
        settingsButton.image = settingsImage
        settingsButton.toolTip = "Settings"
        addSubview(settingsButton)
    }
    
    private func setupGitHubButton() {
        githubButton = NSButton()
        githubButton.translatesAutoresizingMaskIntoConstraints = false
        githubButton.isBordered = false
        githubButton.bezelStyle = .inline
        githubButton.target = self
        githubButton.action = #selector(openGitHub)
        
        // Use user's exact GitHub SVG
        let githubImage = createImageFromUserSVG(userGitHubSVG())
        githubButton.image = githubImage
        githubButton.toolTip = "Visit GitHub"
        addSubview(githubButton)
    }
    
    private func setupRefreshButton() {
        refreshButton = NSButton()
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.isBordered = false
        refreshButton.bezelStyle = .inline
        refreshButton.target = self
        refreshButton.action = #selector(refreshEmail)
        
        // Use user's exact refresh SVG
        let refreshImage = createImageFromUserSVG(userRefreshSVG())
        refreshButton.image = refreshImage
        refreshButton.toolTip = "Refresh Email"
        addSubview(refreshButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Home button - left side
            homeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            homeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            homeButton.widthAnchor.constraint(equalToConstant: 140), // Increased width for full "GProMail" text
            homeButton.heightAnchor.constraint(equalToConstant: 36), // Increased height for better button feel
            
            // Home button background - inside home button
            homeButtonBackground.leadingAnchor.constraint(equalTo: homeButton.leadingAnchor, constant: 6),
            homeButtonBackground.centerYAnchor.constraint(equalTo: homeButton.centerYAnchor),
            homeButtonBackground.widthAnchor.constraint(equalToConstant: 128), // Increased background width
            homeButtonBackground.heightAnchor.constraint(equalToConstant: 32), // Increased background height
            
            // App icon - inside home button background
            appIconView.leadingAnchor.constraint(equalTo: homeButtonBackground.leadingAnchor, constant: 10),
            appIconView.centerYAnchor.constraint(equalTo: homeButtonBackground.centerYAnchor),
            appIconView.widthAnchor.constraint(equalToConstant: 24),
            appIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title label - inside home button background
            titleLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 10),
            titleLabel.centerYAnchor.constraint(equalTo: homeButtonBackground.centerYAnchor),
            
            // Settings button - right side, left of refresh
            settingsButton.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            settingsButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Refresh button - right side, left of GitHub
            refreshButton.trailingAnchor.constraint(equalTo: githubButton.leadingAnchor, constant: -8),
            refreshButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.heightAnchor.constraint(equalToConstant: 30),
            
            // GitHub button - right edge
            githubButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            githubButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            githubButton.widthAnchor.constraint(equalToConstant: 30),
            githubButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    @objc private func openGitHub() {
        if let url = URL(string: "https://github.com/bunnysayzz") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func refreshEmail() {
        webView?.reload()
    }
    
    private func createImageFromUserSVG(_ svgString: String) -> NSImage? {
        guard let svgData = svgString.data(using: .utf8) else { return nil }
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".svg")
        do {
            try svgData.write(to: tempURL)
            let image = NSImage(contentsOf: tempURL)
            try? FileManager.default.removeItem(at: tempURL)
            if let originalImage = image {
                let targetSize = NSSize(width: 24, height: 24)
                let resizedImage = NSImage(size: targetSize)
                resizedImage.lockFocus()
                originalImage.draw(in: NSRect(origin: .zero, size: targetSize))
                resizedImage.unlockFocus()
                return resizedImage
            }
        } catch {
            print("Error creating image from SVG: \(error)")
        }
        return nil
    }
    
    private func userGitHubSVG() -> String {
        return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="24" height="24">
          <path fill="#fff" d="M41,24c0,9.4-7.6,17-17,17S7,33.4,7,24S14.6,7,24,7S41,14.6,41,24z"/>
          <path fill="#455a64" d="M21 41v-5.5c0-.3.2-.5.5-.5s.5.2.5.5V41h2v-6.5c0-.3.2-.5.5-.5s.5.2.5.5V41h2v-5.5c0-.3.2-.5.5-.5s.5.2.5.5V41h1.8c.2-.3.2-.6.2-1.1V36c0-2.2-1.9-5.2-4.3-5.2h-2.5c-2.3 0-4.3 3.1-4.3 5.2v3.9c0 .4.1.8.2 1.1L21 41 21 41zM40.1 26.4C40.1 26.4 40.1 26.4 40.1 26.4c0 0-1.3-.4-2.4-.4 0 0-.1 0-.1 0-1.1 0-2.9.3-2.9.3-.1 0-.1 0-.1-.1 0-.1 0-.1.1-.1.1 0 2-.3 3.1-.3 1.1 0 2.4.4 2.5.4.1 0 .1.1.1.2C40.2 26.3 40.2 26.4 40.1 26.4zM39.8 27.2C39.8 27.2 39.8 27.2 39.8 27.2c0 0-1.4-.4-2.6-.4-.9 0-3 .2-3.1.2-.1 0-.1 0-.1-.1 0-.1 0-.1.1-.1.1 0 2.2-.2 3.1-.2 1.3 0 2.6.4 2.6.4.1 0 .1.1.1.2C39.9 27.1 39.9 27.2 39.8 27.2zM7.8 26.4c-.1 0-.1 0-.1-.1 0-.1 0-.1.1-.2.8-.2 2.4-.5 3.3-.5.8 0 3.5.2 3.6.2.1 0 .1.1.1.1 0 .1-.1.1-.1.1 0 0-2.7-.2-3.5-.2C10.1 26 8.6 26.2 7.8 26.4 7.8 26.4 7.8 26.4 7.8 26.4zM8.2 27.9c0 0-.1 0-.1-.1 0-.1 0-.1 0-.2.1 0 1.4-.8 2.9-1 1.3-.2 4 .1 4.2.1.1 0 .1.1.1.1 0 .1-.1.1-.1.1 0 0 0 0 0 0 0 0-2.8-.3-4.1-.1C9.6 27.1 8.2 27.9 8.2 27.9 8.2 27.9 8.2 27.9 8.2 27.9z"/>
          <path fill="#455a64" d="M14.2,23.5c0-4.4,4.6-8.5,10.3-8.5c5.7,0,10.3,4,10.3,8.5S31.5,31,24.5,31S14.2,27.9,14.2,23.5z"/>
          <path fill="#455a64" d="M28.6 16.3c0 0 1.7-2.3 4.8-2.3 1.2 1.2.4 4.8 0 5.8L28.6 16.3zM20.4 16.3c0 0-1.7-2.3-4.8-2.3-1.2 1.2-.4 4.8 0 5.8L20.4 16.3zM20.1 35.9c0 0-2.3 0-2.8 0-1.2 0-2.3-.5-2.8-1.5-.6-1.1-1.1-2.3-2.6-3.3-.3-.2-.1-.4.4-.4.5.1 1.4.2 2.1 1.1.7.9 1.5 2 2.8 2 1.3 0 2.7 0 3.5-.9L20.1 35.9z"/>
          <path fill="#00bcd4" d="M24,4C13,4,4,13,4,24s9,20,20,20s20-9,20-20S35,4,24,4z M24,40c-8.8,0-16-7.2-16-16S15.2,8,24,8 s16,7.2,16,16S32.8,40,24,40z"/>
        </svg>
        """
    }
    
    private func userRefreshSVG() -> String {
        return """
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 128 128">
          <!-- Envelope body -->
          <rect x="12" y="24" width="104" height="72" rx="8" fill="#2196F3"/>
          
          <!-- Envelope flap -->
          <path d="M12 24 L64 64 L116 24 Z" fill="#42A5F5"/>
          
          <!-- Refresh circle -->
          <circle cx="100" cy="96" r="24" fill="#009688"/>
          
          <!-- Refresh arrow -->
          <path d="M100 80 
                   a16 16 0 1 0 11.3 4.7" 
                fill="none" stroke="white" stroke-width="4" stroke-linecap="round"/>
          <path d="M116 84 L108 82 L111 90 Z" fill="white"/>
        </svg>
        """
    }
    
    private func userSettingsSVG() -> String {
        return """
        <svg width="24" height="24" viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect width="48" height="48" fill="white" fill-opacity="0.01"/>
          <path d="M18.2838 43.1712C14.9327 42.1735 11.9498 40.3212 9.58787 37.8669C10.469 36.8226 11 35.4733 11 34C11 30.6863 8.31371 28 5 28C4.79955 28 4.60139 28.0098 4.40599 28.029C4.13979 26.7276 4 25.3801 4 24C4 21.9094 4.32077 19.8937 4.91579 17.9994C4.94381 17.9998 4.97188 18 5 18C8.31371 18 11 15.3137 11 12C11 11.0487 10.7786 10.1491 10.3846 9.34999C12.6975 7.19937 15.5205 5.5899 18.6521 4.72302C19.6444 6.66807 21.6667 8.00001 24 8.00001C26.3333 8.00001 28.3556 6.66807 29.3479 4.72302C32.4795 5.5899 35.3025 7.19937 37.6154 9.34999C37.2214 10.1491 37 11.0487 37 12C37 15.3137 39.6863 18 43 18C43.0281 18 43.0562 17.9998 43.0842 17.9994C43.6792 19.8937 44 21.9094 44 24C44 25.3801 43.8602 26.7276 43.594 28.029C43.3986 28.0098 43.2005 28 43 28C39.6863 28 37 30.6863 37 34C37 35.4733 37.531 36.8226 38.4121 37.8669C36.0502 40.3212 33.0673 42.1735 29.7162 43.1712C28.9428 40.7518 26.676 39 24 39C21.324 39 19.0572 40.7518 18.2838 43.1712Z" fill="#2F88FF" stroke="#000000" stroke-width="4" stroke-linejoin="round"/>
          <path d="M24 31C27.866 31 31 27.866 31 24C31 20.134 27.866 17 24 17C20.134 17 17 20.134 17 24C17 27.866 20.134 31 24 31Z" fill="#43CCF8" stroke="white" stroke-width="4" stroke-linejoin="round"/>
        </svg>
        """
    }
    
    @objc private func openSettings() {
        // Settings functionality will be added later
        print("Settings button clicked - functionality will be added later")
    }
} 