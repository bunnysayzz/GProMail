# GProMail - Gmail Desktop Client

A native macOS desktop client for Gmail with modern Sparkle update system.

## Features

- 🚀 Native macOS app for Gmail
- 🔄 Automatic updates via Sparkle
- 🔒 Secure EdDSA signing for updates
- 🎨 Modern UI with native macOS integration
- 💾 Window state persistence

## Quick Setup

### 1. Enable GitHub Pages

To enable the update system, you need to set up GitHub Pages:

1. Go to your repository: https://github.com/bunnysayzz/GProMail
2. Click **Settings** tab
3. Scroll down to **Pages** section
4. Under **Source**, select **GitHub Actions**
5. Click **Save**

This will automatically deploy your appcast to `https://bunnysayzz.github.io/GProMail/appcast.xml`

### 2. Build and Test

```bash
# Build the app
xcodebuild build -project GProMail.xcodeproj -scheme GProMail -configuration Release

# Open the built app
open /Users/mdazharuddin/Library/Developer/Xcode/DerivedData/GProMail-*/Build/Products/Release/GProMail.app
```

### 3. Test Updates

The app is currently set to version `0.2.2` and will detect updates to `0.2.3` from the appcast.

## Update System

### How It Works

1. **Appcast**: XML file hosted on GitHub Pages at `https://bunnysayzz.github.io/GProMail/appcast.xml`
2. **Signing**: Uses EdDSA keys for secure update verification
3. **GitHub Integration**: Updates are distributed via GitHub releases

### Creating a New Release

1. Build your app and create a DMG
2. Run the update script:
   ```bash
   ./update_appcast.sh
   ```
3. Create a GitHub release with the DMG file
4. Push the updated appcast to trigger GitHub Pages deployment

## Development

### Requirements

- macOS 10.15+
- Xcode 15+
- No Apple Developer ID required (uses local signing)

### Project Structure

```
GProMail/
├── GProMail/                 # Main app source
├── Sparkle.framework/        # Update framework
├── sparkle_keys/            # EdDSA signing keys
├── appcast.xml              # Update feed
├── update_appcast.sh        # Update signing script
└── .github/workflows/       # GitHub Actions
```

### Code Signing

The app is configured for development without a Developer ID:
- `CODE_SIGN_IDENTITY = "-"`
- `CODE_SIGN_STYLE = Manual`
- `ENABLE_HARDENED_RUNTIME = NO`

## Troubleshooting

### Update Not Working?

1. Check if GitHub Pages is enabled and accessible
2. Verify the appcast URL in `Info.plist`
3. Ensure the app version is lower than the appcast version
4. Check the EdDSA signature in the appcast

### Build Issues?

1. Clean the build: `xcodebuild clean`
2. Check Sparkle framework architecture (should be arm64 for Apple Silicon)
3. Verify all dependencies are properly linked

## License

Copyright © 2024 GProMail. All rights reserved.
