#!/bin/bash

# GProMail Build Script
# This script builds the GProMail app with proper code signing and creates a DMG
# Requires: Xcode, Developer ID certificate, and proper Sparkle signing keys

set -e  # Exit on any error

# Configuration - Update these variables for your setup
APP_NAME="GProMail"
BUNDLE_ID="com.gpromail.app"
PROJECT_NAME="GProMail"
SCHEME_NAME="GProMail"
CONFIGURATION="Release"

# Signing configuration - Set these to your actual identities
DEVELOPER_ID_APPLICATION=""  # e.g., "Developer ID Application: Your Name (XXXXXXXXXX)"
DEVELOPER_ID_INSTALLER=""    # e.g., "Developer ID Installer: Your Name (XXXXXXXXXX)"

# Paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
ARCHIVE_DIR="${BUILD_DIR}/archive"
EXPORT_DIR="${BUILD_DIR}/export"
DMG_DIR="${BUILD_DIR}/dmg"
DIST_DIR="${BUILD_DIR}/dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are available
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild not found. Please install Xcode."
        exit 1
    fi
    
    if ! command -v create-dmg &> /dev/null; then
        log_warning "create-dmg not found. Installing via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install create-dmg
        else
            log_error "Homebrew not found. Please install create-dmg manually or install Homebrew."
            exit 1
        fi
    fi
    
    # Check for signing identity
    if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
        log_warning "DEVELOPER_ID_APPLICATION not set. App will not be signed."
        log_warning "Set DEVELOPER_ID_APPLICATION variable to sign the app."
    else
        # Verify the signing identity exists
        if ! security find-identity -v -p codesigning | grep -q "$DEVELOPER_ID_APPLICATION"; then
            log_error "Signing identity '$DEVELOPER_ID_APPLICATION' not found in keychain."
            log_info "Available identities:"
            security find-identity -v -p codesigning
            exit 1
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Function to clean build directories
clean_build() {
    log_info "Cleaning build directories..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}" "${ARCHIVE_DIR}" "${EXPORT_DIR}" "${DMG_DIR}" "${DIST_DIR}"
    log_success "Build directories cleaned"
}

# Function to build and archive the project
build_archive() {
    log_info "Building and archiving ${PROJECT_NAME}..."
    
    local archive_path="${ARCHIVE_DIR}/${PROJECT_NAME}.xcarchive"
    
    if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
        # Build with signing
        xcodebuild archive \
            -project "${PROJECT_ROOT}/${PROJECT_NAME}.xcodeproj" \
            -scheme "${SCHEME_NAME}" \
            -configuration "${CONFIGURATION}" \
            -archivePath "${archive_path}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            CODE_SIGN_IDENTITY="$DEVELOPER_ID_APPLICATION" \
            CODE_SIGN_STYLE=Manual \
            OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
            2>&1 | (xcpretty 2>/dev/null || cat) || exit 1
    else
        # Build without signing  
        xcodebuild archive \
            -project "${PROJECT_ROOT}/${PROJECT_NAME}.xcodeproj" \
            -scheme "${SCHEME_NAME}" \
            -configuration "${CONFIGURATION}" \
            -archivePath "${archive_path}" \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGN_STYLE=Manual \
            2>&1 | (xcpretty 2>/dev/null || cat) || exit 1
    fi
    
    log_success "Archive created successfully"
    return 0
}

# Function to export the app from archive
export_app() {
    log_info "Exporting app from archive..."
    
    local archive_path="${ARCHIVE_DIR}/${PROJECT_NAME}.xcarchive"
    local export_plist="${BUILD_DIR}/ExportOptions.plist"
    
    # Create export options plist based on whether we have signing identity
    if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
        # Export for Developer ID distribution
        cat > "${export_plist}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$(security find-identity -v -p codesigning | grep "$DEVELOPER_ID_APPLICATION" | head -1 | sed 's/.*(\([^)]*\)).*/\1/' || echo "")</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>$DEVELOPER_ID_APPLICATION</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    else
        # Export without signing (mac application)
        cat > "${export_plist}" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    fi
    
    xcodebuild -exportArchive \
        -archivePath "${archive_path}" \
        -exportPath "${EXPORT_DIR}" \
        -exportOptionsPlist "${export_plist}" \
        2>&1 | (xcpretty 2>/dev/null || cat) || exit 1
    
    log_success "App exported successfully"
}

# Function to sign the Sparkle framework
sign_sparkle_framework() {
    if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
        log_warning "Skipping Sparkle framework signing (no signing identity)"
        return 0
    fi
    
    log_info "Signing Sparkle framework..."
    
    local app_path="${EXPORT_DIR}/${APP_NAME}.app"
    local sparkle_framework="${app_path}/Contents/Frameworks/Sparkle.framework"
    
    if [ -d "$sparkle_framework" ]; then
        codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
            --timestamp --options runtime \
            "$sparkle_framework/Versions/Current/Autoupdate.app"
        
        codesign --force --verify --verbose --sign "$DEVELOPER_ID_APPLICATION" \
            --timestamp --options runtime \
            "$sparkle_framework"
        
        log_success "Sparkle framework signed"
    else
        log_warning "Sparkle framework not found at expected location"
    fi
}

# Function to notarize the app (optional)
notarize_app() {
    if [ -z "$DEVELOPER_ID_APPLICATION" ]; then
        log_warning "Skipping notarization (no signing identity)"
        return 0
    fi
    
    log_info "Starting notarization process..."
    log_warning "Notarization requires App Store Connect API key or app-specific password"
    log_info "You can notarize manually using: xcrun notarytool submit ..."
    
    # Uncomment and configure the following lines for automatic notarization:
    # xcrun notarytool submit "${EXPORT_DIR}/${APP_NAME}.app" \
    #     --keychain-profile "AC_PASSWORD" \
    #     --wait
    #
    # xcrun stapler staple "${EXPORT_DIR}/${APP_NAME}.app"
}

# Function to create DMG
create_dmg() {
    log_info "Creating DMG..."
    
    # Clean up any existing DMG files in root folder
    if ls "${PROJECT_ROOT}"/GProMail-*.dmg 1> /dev/null 2>&1; then
        log_info "Removing existing DMG files..."
        rm -f "${PROJECT_ROOT}"/GProMail-*.dmg
    fi
    
    local app_path="${EXPORT_DIR}/${APP_NAME}.app"
    local version=$(defaults read "${app_path}/Contents/Info.plist" CFBundleShortVersionString)
    local dmg_name="GProMail-${version}.dmg"
    local dmg_path="${PROJECT_ROOT}/${dmg_name}"  # Changed to root folder
    
    # Copy app to DMG staging directory
    cp -R "${app_path}" "${DMG_DIR}/"
    
    # Create DMG with nice layout
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${app_path}/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 800 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 200 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 600 185 \
        --hdiutil-verbose \
        "${dmg_path}" \
        "${DMG_DIR}/" || {
        # Fallback to hdiutil if create-dmg fails
        log_warning "create-dmg failed, falling back to hdiutil"
        hdiutil create -srcfolder "${DMG_DIR}" -format UDZO -imagekey zlib-level=9 "${dmg_path}"
    }
    
    # Sign the DMG if we have a signing identity
    if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
        log_info "Signing DMG..."
        codesign --force --sign "$DEVELOPER_ID_APPLICATION" --timestamp "${dmg_path}"
        log_success "DMG signed"
    fi
    
    log_success "DMG created in root folder: ${dmg_name}"
    
    # Display file info
    ls -lh "${dmg_path}"
    
    # Verify the DMG
    hdiutil verify "${dmg_path}"
    log_success "DMG verification completed"
}

# Function to generate Sparkle signing keys
generate_sparkle_keys() {
    log_info "Generating Sparkle EdDSA signing keys..."
    
    local keys_dir="${PROJECT_ROOT}/sparkle_keys"
    mkdir -p "${keys_dir}"
    
    if [ -f "${keys_dir}/eddsa_pub.pem" ] && [ -f "${keys_dir}/eddsa_priv.pem" ]; then
        log_warning "Sparkle keys already exist. Skipping generation."
        log_info "Public key: ${keys_dir}/eddsa_pub.pem"
        log_info "Private key: ${keys_dir}/eddsa_priv.pem"
        return 0
    fi
    
    # Check if Sparkle's generate_keys tool exists
    local generate_keys_tool=""
    if [ -f "/usr/local/bin/generate_keys" ]; then
        generate_keys_tool="/usr/local/bin/generate_keys"
    elif [ -f "${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/generate_keys" ]; then
        generate_keys_tool="${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/generate_keys"
    else
        log_warning "Sparkle's generate_keys tool not found."
        log_info "You can generate keys manually using Sparkle's generate_keys tool"
        log_info "Or download it from: https://github.com/sparkle-project/Sparkle/releases"
        return 1
    fi
    
    cd "${keys_dir}"
    "${generate_keys_tool}"
    
    log_success "Sparkle signing keys generated:"
    log_info "Public key: ${keys_dir}/eddsa_pub.pem"
    log_info "Private key: ${keys_dir}/eddsa_priv.pem"
    log_warning "Keep the private key secure and never commit it to version control!"
}

# Function to display usage information
usage() {
    cat << EOF
Usage: $0 [options]

Options:
    --help                  Show this help message
    --clean                 Clean build directories only
    --generate-keys         Generate Sparkle EdDSA signing keys only
    --skip-notarization     Skip the notarization step
    --developer-id-app ID   Set Developer ID Application signing identity
    --developer-id-inst ID  Set Developer ID Installer signing identity

Environment Variables:
    DEVELOPER_ID_APPLICATION    Developer ID Application signing identity
    DEVELOPER_ID_INSTALLER      Developer ID Installer signing identity

Example:
    $0 --developer-id-app "Developer ID Application: Your Name (XXXXXXXXXX)"
    
EOF
}

# Parse command line arguments
SKIP_NOTARIZATION=false
CLEAN_ONLY=false
GENERATE_KEYS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            usage
            exit 0
            ;;
        --clean)
            CLEAN_ONLY=true
            shift
            ;;
        --generate-keys)
            GENERATE_KEYS_ONLY=true
            shift
            ;;
        --skip-notarization)
            SKIP_NOTARIZATION=true
            shift
            ;;
        --developer-id-app)
            DEVELOPER_ID_APPLICATION="$2"
            shift 2
            ;;
        --developer-id-inst)
            DEVELOPER_ID_INSTALLER="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_info "Starting GProMail build process..."
    
    if [ "$GENERATE_KEYS_ONLY" = true ]; then
        generate_sparkle_keys
        exit 0
    fi
    
    if [ "$CLEAN_ONLY" = true ]; then
        clean_build
        exit 0
    fi
    
    # Execute build steps
    check_prerequisites
    clean_build
    build_archive
    export_app
    sign_sparkle_framework
    
    if [ "$SKIP_NOTARIZATION" = false ]; then
        notarize_app
    fi
    
    create_dmg
    
    log_success "Build process completed successfully!"
    log_info "Output files:"
    log_info "  App: ${EXPORT_DIR}/${APP_NAME}.app"
    
    # Get the actual DMG filename with version
    local version=$(defaults read "${EXPORT_DIR}/${APP_NAME}.app/Contents/Info.plist" CFBundleShortVersionString)
    log_info "  DMG: ${PROJECT_ROOT}/GProMail-${version}.dmg"
    
    # Display signing verification
    if [ -n "$DEVELOPER_ID_APPLICATION" ]; then
        log_info "Code signing verification:"
        codesign -dv "${EXPORT_DIR}/${APP_NAME}.app" 2>&1 | grep -E "Authority|TeamIdentifier|Identifier"
    fi
}

# Run main function
main "$@" 