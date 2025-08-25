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
    private var githubButton: NSButton!
    private var refreshButton: NSButton!
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
        
        setupAppIcon()
        setupTitleLabel()
        setupGitHubButton()
        setupRefreshButton()
        setupConstraints()
    }
    
    override func layout() {
        super.layout()
        gradientLayer?.frame = bounds
    }
    
    private func setupAppIcon() {
        appIconView = NSImageView()
        appIconView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the app icon from the bundle
        if let appIcon = NSApp.applicationIconImage {
            appIconView.image = appIcon
        } else {
            // Fallback to bundle icon
            appIconView.image = NSImage(named: "AppIcon")
        }
        
        appIconView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(appIconView)
    }
    
    private func setupTitleLabel() {
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = "GProMail"
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = NSColor.clear
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = NSColor.labelColor
        addSubview(titleLabel)
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
            // App icon - left side
            appIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            appIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            appIconView.widthAnchor.constraint(equalToConstant: 24),
            appIconView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title label - next to app icon
            titleLabel.leadingAnchor.constraint(equalTo: appIconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // GitHub button - right edge
            githubButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            githubButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            githubButton.widthAnchor.constraint(equalToConstant: 30),
            githubButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Refresh button - left of GitHub button
            refreshButton.trailingAnchor.constraint(equalTo: githubButton.leadingAnchor, constant: -8),
            refreshButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.heightAnchor.constraint(equalToConstant: 30)
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
} 