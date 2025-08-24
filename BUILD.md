# GProMail Build Instructions

This document provides comprehensive instructions for building and distributing the GProMail application with proper code signing and automatic updates via Sparkle.

## Prerequisites

### Required Software
- **Xcode** (latest version recommended)
- **macOS Developer Account** for code signing certificates
- **Homebrew** (for installing additional tools)

### Required Tools
Install the following tools if not already present:

```bash
# Install create-dmg for DMG creation
brew install create-dmg

# Install xcpretty for prettier build output (optional but recommended)  
gem install xcpretty
```

### Code Signing Setup

1. **Get Apple Developer ID Certificate:**
   - Enroll in Apple Developer Program ($99/year)
   - Generate a "Developer ID Application" certificate
   - Download and install it in your macOS Keychain

2. **Verify Certificate Installation:**
   ```bash
   security find-identity -v -p codesigning
   ```
   You should see your "Developer ID Application" certificate listed.

## Initial Setup

### 1. Set Up Sparkle Signing (First Time Only)

Run the setup script to configure Sparkle with modern EdDSA signing:

```bash
./setup_sparkle.sh
```

This script will:
- Generate EdDSA signing keys for Sparkle updates
- Update `Info.plist` with the public key
- Create necessary build scripts and templates
- Update `.gitignore` to protect private keys

**Important:** The private key (`sparkle_keys/eddsa_priv.pem`) must be kept secure and never committed to version control!

### 2. Configure Update Server

1. **Edit `Info.plist`:**
   Update the `SUFeedURL` to point to your update server:
   ```xml
   <key>SUFeedURL</key>
   <string>https://your-domain.com/appcast.xml</string>
   ```

2. **Prepare Server:**
   - Set up HTTPS server for hosting updates
   - Upload `appcast_template.xml` as `appcast.xml`
   - Ensure proper CORS headers if needed

## Building the Application

### Basic Build (Without Code Signing)

For development builds without signing:

```bash
./build.sh --skip-notarization
```

### Production Build (With Code Signing)

For distribution builds with proper signing:

```bash
./build.sh --developer-id-app "Developer ID Application: Your Name (TEAM_ID)"
```

Replace `"Developer ID Application: Your Name (TEAM_ID)"` with your actual certificate name as shown in Keychain Access.

### Build Options

The `build.sh` script supports several options:

```bash
# Show help
./build.sh --help

# Clean build directories only
./build.sh --clean

# Generate Sparkle keys only
./build.sh --generate-keys

# Skip notarization (faster for testing)
./build.sh --skip-notarization --developer-id-app "Your Certificate"

# Full production build
./build.sh --developer-id-app "Your Certificate"
```

### Build Output

After a successful build, you'll find:
- **Application**: `build/export/GProMail.app`
- **DMG**: `build/dist/GProMail-VERSION.dmg`

## Distributing Updates

### 1. Build New Version

1. Update version numbers in `Info.plist`:
   ```xml
   <key>CFBundleShortVersionString</key>
   <string>1.1.0</string>
   <key>CFBundleVersion</key>
   <string>30</string>
   ```

2. Build the application:
   ```bash
   ./build.sh --developer-id-app "Your Certificate"
   ```

### 2. Sign the Update

Generate the Sparkle signature for the DMG:

```bash
./sign_update.sh build/dist/GProMail-1.1.0.dmg
```

This will output an EdDSA signature like:
```
EdDSA signature: MC0CFQCdoW5j3QdHzPQmkz89vWxwQxTSgAAAAhUAkdkw8NCGc...
```

### 3. Update Appcast

Edit your `appcast.xml` on the server and add a new item:

```xml
<item>
    <title>Version 1.1.0</title>
    <link>https://your-domain.com/releases/GProMail-1.1.0.dmg</link>
    <sparkle:version>1.1.0</sparkle:version>
    <sparkle:shortVersionString>1.1.0</sparkle:shortVersionString>
    <description><![CDATA[
        <ul>
            <li>Bug fixes and improvements</li>
            <li>Enhanced Gmail integration</li>
        </ul>
    ]]></description>
    <pubDate>Mon, 15 Jan 2024 10:00:00 +0000</pubDate>
    <enclosure 
        url="https://your-domain.com/releases/GProMail-1.1.0.dmg" 
        sparkle:version="1.1.0" 
        sparkle:shortVersionString="1.1.0" 
        sparkle:edSignature="MC0CFQCdoW5j3QdHzPQmkz89vWxwQxTSgAAAAhUAkdkw8NCGc..."
        length="12345678" 
        type="application/octet-stream" />
</item>
```

### 4. Upload Files

Upload both files to your server:
- The DMG file to your releases directory
- The updated `appcast.xml` to your server root

## Notarization (Optional but Recommended)

For maximum compatibility and security, notarize your app with Apple:

### 1. Set Up App Store Connect API

1. Create an API key in App Store Connect
2. Download the `.p8` key file  
3. Note the Key ID and Issuer ID

### 2. Configure Notarization

Edit the `notarize_app()` function in `build.sh` to enable automatic notarization:

```bash
# Uncomment and configure these lines:
xcrun notarytool submit "${EXPORT_DIR}/${APP_NAME}.app" \
    --key "/path/to/AuthKey_KEYID.p8" \
    --key-id "YOUR_KEY_ID" \
    --issuer "YOUR_ISSUER_ID" \
    --wait

xcrun stapler staple "${EXPORT_DIR}/${APP_NAME}.app"
```

### 3. Build with Notarization

```bash
./build.sh --developer-id-app "Your Certificate"
```

The build process will automatically submit your app for notarization and staple the ticket.

## Troubleshooting

### Common Build Issues

1. **"No signing identity found"**
   - Verify your Developer ID certificate is installed
   - Check certificate name matches exactly

2. **"create-dmg not found"**
   ```bash
   brew install create-dmg
   ```

3. **"xcpretty not found"**
   ```bash
   gem install xcpretty
   ```

### Code Signing Issues

1. **"errSecInternalComponent"**
   - Restart Xcode and try again
   - Check Keychain Access for certificate issues

2. **"timestamp server not responding"**
   - Retry the build (temporary Apple server issue)
   - Check internet connection

### Sparkle Issues

1. **"Keys not found"**
   ```bash
   ./setup_sparkle.sh
   ```

2. **"Invalid signature"**
   - Ensure you're using the correct private key
   - Verify the DMG wasn't corrupted during upload

## File Structure

After setup, your project will have:

```
GProMail-master/
├── build.sh                 # Main build script
├── setup_sparkle.sh          # Sparkle setup script  
├── sign_update.sh            # Update signing script
├── BUILD.md                  # This documentation
├── appcast_template.xml      # Appcast template
├── sparkle_keys/            # Signing keys (private key not committed)
│   ├── eddsa_pub.pem        # Public key
│   └── eddsa_priv.pem       # Private key (gitignored)
├── build/                   # Build output (created during build)
│   ├── export/
│   └── dist/
└── GProMail/               # Source code (project files)
    ├── Info.plist           # Updated with public key
    └── ...
```

## Security Considerations

1. **Never commit private keys** - The `.gitignore` file prevents this
2. **Use HTTPS** for your update server
3. **Verify signatures** before distributing updates  
4. **Keep certificates secure** - Store in secure keychain
5. **Regular backups** of signing keys and certificates

## CI/CD Integration

For automated builds, consider:

1. **Store secrets securely** (certificates, API keys)
2. **Use separate signing identity** for CI/CD
3. **Implement signature verification** in your pipeline
4. **Automated testing** before deployment

Example GitHub Actions workflow structure:
- Install dependencies
- Import certificates
- Run build script
- Sign and notarize
- Upload releases
- Update appcast

## Support

For issues with:
- **Build script**: Check this documentation and script help
- **Sparkle**: See [Sparkle documentation](https://sparkle-project.org/)
- **Code signing**: Refer to Apple's developer documentation
- **Notarization**: Check Apple's notarization guide

## Version History

- **v1.0**: Initial build system with DSA signing
- **v2.0**: Modern EdDSA signing with automated build pipeline 