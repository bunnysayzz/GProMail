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
        
        setupTitleLabel()
        setupGitHubButton()
        setupRefreshButton()
        setupConstraints()
    }
    
    override func layout() {
        super.layout()
        gradientLayer?.frame = bounds
    }
    
    private func setupTitleLabel() {
        titleLabel = NSTextField()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = "GProMail for Gmail"
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
        
        // Create GitHub icon with version compatibility
        if #available(macOS 11.0, *) {
            // Use SF Symbols for macOS 11.0+
            let githubImage = NSImage(systemSymbolName: "link.circle.fill", accessibilityDescription: "GitHub")
            let config = NSImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            let configuredImage = githubImage?.withSymbolConfiguration(config)
            githubButton.image = configuredImage
        } else {
            // Fallback for macOS 10.15
            githubButton.title = "🔗"
            githubButton.font = NSFont.systemFont(ofSize: 16)
        }
        
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
        
        // Create refresh icon
        if #available(macOS 11.0, *) {
            let refreshImage = NSImage(systemSymbolName: "arrow.clockwise.circle", accessibilityDescription: "Refresh")
            let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let configuredImage = refreshImage?.withSymbolConfiguration(config)
            refreshButton.image = configuredImage
        } else {
            refreshButton.title = "🔄"
            refreshButton.font = NSFont.systemFont(ofSize: 14)
        }
        
        refreshButton.toolTip = "Refresh Email"
        addSubview(refreshButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title label - left side
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Refresh button - right side
            refreshButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            refreshButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 30),
            refreshButton.heightAnchor.constraint(equalToConstant: 30),
            
            // GitHub button - next to refresh button
            githubButton.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -8),
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
} 