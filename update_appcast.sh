#!/bin/bash

# GProMail Appcast Update Script
# This script signs a DMG file and updates the appcast.xml

set -e

# Configuration
APP_NAME="GProMail"
VERSION="0.2.3"
BUILD_NUMBER="25"
DMG_FILE="GProMail-${VERSION}.dmg"
PRIVATE_KEY="sparkle_keys/eddsa_priv.pem"
APPCAST_FILE="appcast.xml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if DMG file exists
if [ ! -f "$DMG_FILE" ]; then
    log_error "DMG file not found: $DMG_FILE"
    log_info "Please build the app first using: ./build.sh"
    exit 1
fi

# Check if private key exists
if [ ! -f "$PRIVATE_KEY" ]; then
    log_error "Private key not found: $PRIVATE_KEY"
    log_info "Please generate Sparkle keys first using: ./setup_sparkle.sh"
    exit 1
fi

# Get file size
FILE_SIZE=$(stat -f%z "$DMG_FILE")
log_info "DMG file size: $FILE_SIZE bytes"

# Sign the DMG file
log_info "Signing DMG file with EdDSA key..."
SIGNATURE=$(./sparkle_tools/sign_update "$DMG_FILE" "$PRIVATE_KEY")

if [ $? -eq 0 ]; then
    log_success "DMG file signed successfully"
    log_info "Signature: $SIGNATURE"
else
    log_error "Failed to sign DMG file"
    exit 1
fi

# Update appcast.xml with the signature
log_info "Updating appcast.xml..."

# Extract just the signature part (remove the length part)
SIGNATURE_ONLY=$(echo "$SIGNATURE" | sed 's/ length="[^"]*"//')

# Create a temporary file
TEMP_APPCAST=$(mktemp)

# Update the appcast with the signature using a safer approach
awk -v sig="$SIGNATURE_ONLY" -v size="$FILE_SIZE" '
    gsub(/sparkle:edSignature="SIGNATURE_WILL_BE_GENERATED"/, "sparkle:edSignature=\"" sig "\"")
    gsub(/length="2500000"/, "length=\"" size "\"")
    { print }
' "$APPCAST_FILE" > "$TEMP_APPCAST"

mv "$TEMP_APPCAST" "$APPCAST_FILE"

log_success "Appcast updated successfully"
log_info "Appcast file: $APPCAST_FILE"
log_info "GitHub Pages URL: https://bunnysayzz.github.io/GProMail/appcast.xml"

# Instructions for GitHub
echo ""
log_info "Next steps:"
echo "1. Commit and push the updated appcast.xml:"
echo "   git add appcast.xml"
echo "   git commit -m 'Update appcast for version $VERSION'"
echo "   git push origin main"
echo ""
echo "2. Create a GitHub release with the DMG file:"
echo "   - Go to: https://github.com/bunnysayzz/GProMail/releases"
echo "   - Create a new release with tag: v$VERSION"
echo "   - Upload: $DMG_FILE"
echo "   - Set release title: GProMail $VERSION"
echo ""
echo "3. Enable GitHub Pages:"
echo "   - Go to repository Settings > Pages"
echo "   - Source: Deploy from a branch"
echo "   - Branch: main, folder: / (root)"
echo "   - Save"
echo ""
echo "4. Test the update in your app!" 