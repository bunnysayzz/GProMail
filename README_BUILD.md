# GProMail Build System - Quick Start

🎉 **Your GProMail build system is now set up!** 

This project has been configured with a modern build pipeline that includes proper code signing and Sparkle automatic updates.

## What Was Created

### 📄 Scripts
- **`build.sh`** - Main build script for creating signed app and DMG
- **`setup_sparkle.sh`** - Sets up Sparkle with EdDSA signing keys  
- **`sign_update.sh`** - Signs updates for Sparkle (created after setup)

### 📋 Documentation
- **`BUILD.md`** - Comprehensive build instructions
- **`README_BUILD.md`** - This quick start guide

### ⚙️ Configuration Changes
- **`Info.plist`** - Updated to use modern EdDSA signing instead of DSA
- **`gInbox.xcodeproj`** - Updated with proper code signing settings (project files in GProMail/)

## Next Steps

### 1. First Time Setup (Required)

Run the Sparkle setup script to generate signing keys:

```bash
./setup_sparkle.sh
```

This will:
- Generate secure EdDSA signing keys for Sparkle
- Update your Info.plist with the public key
- Create additional helper scripts
- Set up .gitignore for security

### 2. Get Developer Certificate

You'll need an Apple Developer ID certificate to sign your app:

1. Enroll in [Apple Developer Program](https://developer.apple.com/) ($99/year)
2. Generate a "Developer ID Application" certificate  
3. Download and install it in Keychain Access

### 3. Test the Build

Try a development build without signing:

```bash
./build.sh --skip-notarization
```

Or with your Developer ID (replace with your certificate name):

```bash
./build.sh --developer-id-app "Developer ID Application: Your Name (TEAM_ID)"
```

### 4. Check Available Certificates

To see your installed certificates:

```bash
security find-identity -v -p codesigning
```

## Build Output

After successful build, you'll find:
- **App**: `build/export/GProMail.app`  
- **DMG**: `build/dist/GProMail-VERSION.dmg`

## Key Features

✅ **Modern Security**: Uses EdDSA instead of legacy DSA signing  
✅ **Automated DMG Creation**: Professional installer packages  
✅ **Code Signing**: Proper macOS app signing with Developer ID  
✅ **Notarization Ready**: Optional Apple notarization support  
✅ **Sparkle Updates**: Secure automatic updates  
✅ **Comprehensive Documentation**: Step-by-step guides  

## Quick Commands

```bash
# Show help
./build.sh --help

# Setup Sparkle (first time only)  
./setup_sparkle.sh

# Development build (no signing)
./build.sh --skip-notarization

# Production build (with signing)
./build.sh --developer-id-app "Your Certificate Name"

# Clean build directories
./build.sh --clean
```

## Important Security Notes

⚠️ **Never commit private keys** - The .gitignore prevents this  
🔒 **Use HTTPS** for your update server  
🔐 **Keep certificates secure** in your keychain  

## Need Help?

- **Detailed Instructions**: See `BUILD.md` for comprehensive documentation
- **Build Issues**: Run `./build.sh --help` for options
- **Sparkle Setup**: Run `./setup_sparkle.sh --help` for Sparkle-specific help

## Project Status

| Component | Status |
|-----------|---------|
| Build Script | ✅ Ready |
| Code Signing | ⚙️ Requires Developer ID |
| Sparkle Updates | ⚙️ Run setup script first |
| DMG Creation | ✅ Ready |
| Documentation | ✅ Complete |

---

**Ready to build?** Start with `./setup_sparkle.sh` then try `./build.sh --help`! 