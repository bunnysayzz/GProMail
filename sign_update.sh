#!/bin/bash

# Script to sign updates for Sparkle
# Usage: ./sign_update.sh /path/to/update.dmg

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-update-file>"
    echo "Example: $0 build/dist/GProMail-1.0.0.dmg"
    exit 1
fi

UPDATE_FILE="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_KEY="${PROJECT_ROOT}/sparkle_keys/eddsa_priv.pem"

if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Error: Private key not found at $PRIVATE_KEY"
    echo "Please ensure Sparkle keys have been generated"
    exit 1
fi

if [ ! -f "$UPDATE_FILE" ]; then
    echo "Error: Update file not found: $UPDATE_FILE"
    exit 1
fi

# Try to find sign_update tool
SIGN_UPDATE_TOOL=""
if [ -f "/usr/local/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="/usr/local/bin/sign_update"
elif [ -f "${PROJECT_ROOT}/sparkle_tools/bin/sign_update" ]; then
    SIGN_UPDATE_TOOL="${PROJECT_ROOT}/sparkle_tools/bin/sign_update"
elif [ -f "${PROJECT_ROOT}/sparkle_tools/sign_update" ]; then
    SIGN_UPDATE_TOOL="${PROJECT_ROOT}/sparkle_tools/sign_update"
elif [ -f "${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/sign_update" ]; then
    SIGN_UPDATE_TOOL="${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/sign_update"
else
    echo "Error: sign_update tool not found"
    echo "Available tools in sparkle_tools:"
    ls -la "${PROJECT_ROOT}/sparkle_tools/"
    echo ""
    echo "You can download Sparkle tools from: https://github.com/sparkle-project/Sparkle/releases"
    exit 1
fi

echo "Using sign_update tool: $SIGN_UPDATE_TOOL"
echo "Signing update file: $UPDATE_FILE"
echo "Using private key: $PRIVATE_KEY"
echo ""

# Sign the update using OpenSSL directly since we have the private key
# Calculate the EdDSA signature
TEMP_SIGNATURE=$(openssl dgst -sha512 -sign "$PRIVATE_KEY" -hex "$UPDATE_FILE" | cut -d' ' -f2)

# Try using the Sparkle tool first
if [ -x "$SIGN_UPDATE_TOOL" ]; then
    echo "Using Sparkle's sign_update tool..."
    SIGNATURE=$("$SIGN_UPDATE_TOOL" "$UPDATE_FILE" "$PRIVATE_KEY" 2>/dev/null) || {
        echo "Sparkle tool failed, using OpenSSL signature method..."
        SIGNATURE="$TEMP_SIGNATURE"
    }
else
    echo "Using OpenSSL signature method..."
    SIGNATURE="$TEMP_SIGNATURE"
fi

echo "EdDSA signature: $SIGNATURE"
echo ""
echo "Use this signature in your appcast.xml:"
echo "sparkle:edSignature=\"$SIGNATURE\""
echo ""
echo "Also include the file size:"
FILE_SIZE=$(stat -f%z "$UPDATE_FILE" 2>/dev/null || stat -c%s "$UPDATE_FILE" 2>/dev/null)
echo "length=\"$FILE_SIZE\"" 