#!/bin/bash

# Sparkle Setup Script for GProMail
# This script helps set up Sparkle with proper EdDSA signing keys
# and updates the project configuration

set -e

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

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${PROJECT_ROOT}/sparkle_keys"
INFO_PLIST="${PROJECT_ROOT}/GProMail/Info.plist"

# Function to download Sparkle tools if not present
download_sparkle_tools() {
    log_info "Checking for Sparkle generate_keys tool..."
    
    local tools_dir="${PROJECT_ROOT}/sparkle_tools"
    local generate_keys_tool="${tools_dir}/generate_keys"
    
    if [ -f "$generate_keys_tool" ]; then
        log_info "Sparkle tools already available"
        echo "$generate_keys_tool"
        return 0
    fi
    
    log_info "Downloading Sparkle tools..."
    mkdir -p "$tools_dir"
    
    # Download the latest Sparkle release
    local sparkle_version="2.5.1"  # Update this to the latest version
    local download_url="https://github.com/sparkle-project/Sparkle/releases/download/${sparkle_version}/Sparkle-${sparkle_version}.tar.xz"
    local temp_file="${tools_dir}/sparkle.tar.xz"
    
    if command -v curl &> /dev/null; then
        curl -L -o "$temp_file" "$download_url" || {
            log_error "Failed to download Sparkle tools"
            return 1
        }
    elif command -v wget &> /dev/null; then
        wget -O "$temp_file" "$download_url" || {
            log_error "Failed to download Sparkle tools"
            return 1
        }
    else
        log_error "Neither curl nor wget found. Please install one of them."
        return 1
    fi
    
    # Extract the tools
    cd "$tools_dir"
    tar -xf "$temp_file"
    
    # Find and copy generate_keys tool
    local extracted_tool=$(find . -name "generate_keys" -type f | head -1)
    if [ -n "$extracted_tool" ]; then
        cp "$extracted_tool" "$generate_keys_tool"
        chmod +x "$generate_keys_tool"
        log_success "Sparkle tools downloaded successfully"
    else
        log_error "Could not find generate_keys tool in downloaded archive"
        return 1
    fi
    
    # Clean up
    rm -rf "$temp_file" Sparkle-*
    
    echo "$generate_keys_tool"
}

# Function to generate EdDSA keys
generate_keys() {
    log_info "Generating Sparkle EdDSA signing keys..."
    
    mkdir -p "$KEYS_DIR"
    
    if [ -f "${KEYS_DIR}/eddsa_pub.pem" ] && [ -f "${KEYS_DIR}/eddsa_priv.pem" ]; then
        log_warning "Sparkle keys already exist."
        read -p "Do you want to regenerate them? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Using existing keys."
            return 0
        fi
        log_warning "Regenerating keys will invalidate existing signed updates!"
    fi
    
    # Try to find or download generate_keys tool
    local generate_keys_tool=""
    
    # Check common locations
    if [ -f "/usr/local/bin/generate_keys" ]; then
        generate_keys_tool="/usr/local/bin/generate_keys"
    elif [ -f "${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/generate_keys" ]; then
        generate_keys_tool="${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/generate_keys"
    else
        generate_keys_tool=$(download_sparkle_tools) || {
            log_error "Could not obtain Sparkle generate_keys tool"
            log_info "Please download Sparkle from https://github.com/sparkle-project/Sparkle/releases"
            log_info "And run the generate_keys tool manually in the ${KEYS_DIR} directory"
            return 1
        }
    fi
    
    # Generate keys
    cd "$KEYS_DIR"
    "$generate_keys_tool" || {
        log_error "Failed to generate keys"
        return 1
    }
    
    log_success "Keys generated successfully!"
    log_info "Public key: ${KEYS_DIR}/eddsa_pub.pem"
    log_info "Private key: ${KEYS_DIR}/eddsa_priv.pem"
    
    # Secure the private key
    chmod 600 "${KEYS_DIR}/eddsa_priv.pem"
    
    log_warning "IMPORTANT: Keep the private key secure and never commit it to version control!"
    log_warning "Add sparkle_keys/ to your .gitignore file"
}

# Function to update Info.plist with the public key
update_info_plist() {
    log_info "Updating Info.plist with EdDSA public key..."
    
    if [ ! -f "${KEYS_DIR}/eddsa_pub.pem" ]; then
        log_error "Public key not found. Please generate keys first."
        return 1
    fi
    
    # Read the public key and convert to base64 format for Sparkle
    local pub_key_content=$(cat "${KEYS_DIR}/eddsa_pub.pem" | grep -v "PUBLIC KEY" | tr -d '\n')
    
    # Update Info.plist
    if grep -q "REPLACE_WITH_YOUR_EDDSA_PUBLIC_KEY" "$INFO_PLIST"; then
        # Replace placeholder
        if command -v sed &> /dev/null; then
            sed -i.bak "s/REPLACE_WITH_YOUR_EDDSA_PUBLIC_KEY/${pub_key_content}/" "$INFO_PLIST"
            log_success "Info.plist updated with public key"
        else
            log_warning "sed not available. Please manually replace 'REPLACE_WITH_YOUR_EDDSA_PUBLIC_KEY' in Info.plist with:"
            log_info "$pub_key_content"
        fi
    else
        log_warning "Placeholder not found in Info.plist. Please verify the SUPublicEDKey entry."
    fi
}

# Function to create .gitignore entry
update_gitignore() {
    local gitignore_file="${PROJECT_ROOT}/.gitignore"
    
    if [ ! -f "$gitignore_file" ]; then
        log_info "Creating .gitignore file..."
        cat > "$gitignore_file" << EOF
# Xcode
build/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
*.xcuserstate
*.xcworkspace/xcuserdata/

# Sparkle private keys
sparkle_keys/eddsa_priv.pem
sparkle_tools/

# Build artifacts
*.dmg
*.app
EOF
    else
        if ! grep -q "sparkle_keys" "$gitignore_file"; then
            log_info "Adding Sparkle keys to .gitignore..."
            echo "" >> "$gitignore_file"
            echo "# Sparkle private keys" >> "$gitignore_file"
            echo "sparkle_keys/eddsa_priv.pem" >> "$gitignore_file"
            echo "sparkle_tools/" >> "$gitignore_file"
        fi
    fi
    
    log_success "Updated .gitignore"
}

# Function to create appcast template
create_appcast_template() {
    log_info "Creating appcast template..."
    
    local appcast_file="${PROJECT_ROOT}/appcast_template.xml"
    
    cat > "$appcast_file" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>gInbox Changelog</title>
        <link>http://your-domain.com/ginbox-appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        
        <!-- Example entry - replace with actual release information -->
        <item>
            <title>Version 1.0.0</title>
            <link>http://your-domain.com/releases/gInbox-1.0.0.dmg</link>
            <sparkle:version>1.0.0</sparkle:version>
            <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
            <description><![CDATA[
                <ul>
                    <li>Initial release</li>
                    <li>Gmail integration</li>
                    <li>Auto-updates via Sparkle</li>
                </ul>
            ]]></description>
            <pubDate>Mon, 01 Jan 2024 10:00:00 +0000</pubDate>
            <enclosure 
                url="http://your-domain.com/releases/gInbox-1.0.0.dmg" 
                sparkle:version="1.0.0" 
                sparkle:shortVersionString="1.0.0" 
                sparkle:edSignature="SIGNATURE_WILL_BE_GENERATED_BY_SIGN_UPDATE_TOOL"
                length="FILE_SIZE_IN_BYTES" 
                type="application/octet-stream" />
        </item>
    </channel>
</rss>
EOF
    
    log_success "Created appcast template: $appcast_file"
    log_info "Edit this file with your actual release information and upload it to your server"
}

# Function to create signing script
create_signing_script() {
    log_info "Creating update signing script..."
    
    local sign_script="${PROJECT_ROOT}/sign_update.sh"
    
    cat > "$sign_script" << 'EOF'
#!/bin/bash

# Script to sign updates for Sparkle
# Usage: ./sign_update.sh /path/to/update.dmg

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-update-file>"
    echo "Example: $0 build/dist/gInbox-1.0.0.dmg"
    exit 1
fi

UPDATE_FILE="$1"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_KEY="${PROJECT_ROOT}/sparkle_keys/eddsa_priv.pem"

if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Error: Private key not found at $PRIVATE_KEY"
    echo "Please run ./setup_sparkle.sh first"
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
elif [ -f "${PROJECT_ROOT}/sparkle_tools/sign_update" ]; then
    SIGN_UPDATE_TOOL="${PROJECT_ROOT}/sparkle_tools/sign_update"
elif [ -f "${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/sign_update" ]; then
    SIGN_UPDATE_TOOL="${PROJECT_ROOT}/Sparkle.framework/Versions/Current/Resources/sign_update"
else
    echo "Error: sign_update tool not found"
    echo "Please ensure Sparkle tools are installed"
    exit 1
fi

# Sign the update
SIGNATURE=$("$SIGN_UPDATE_TOOL" "$UPDATE_FILE" "$PRIVATE_KEY")
echo "EdDSA signature: $SIGNATURE"
echo ""
echo "Use this signature in your appcast.xml:"
echo "sparkle:edSignature=\"$SIGNATURE\""
EOF
    
    chmod +x "$sign_script"
    log_success "Created signing script: $sign_script"
}

# Function to display setup instructions
show_instructions() {
    cat << EOF

${GREEN}===== Sparkle Setup Complete! =====${NC}

${BLUE}Next Steps:${NC}

1. ${YELLOW}Code Signing Setup:${NC}
   - Get an Apple Developer ID certificate
   - Install it in your keychain
   - Update the build.sh script with your signing identity

2. ${YELLOW}Building the App:${NC}
   ${BLUE}./build.sh --developer-id-app "Developer ID Application: Your Name (XXXXXXXXXX)"${NC}

3. ${YELLOW}Creating Updates:${NC}
   - Build a new version of your app
   - Sign the update: ${BLUE}./sign_update.sh build/dist/gInbox-1.0.0.dmg${NC}
   - Update your appcast.xml with the signature
   - Upload both the DMG and appcast.xml to your server

4. ${YELLOW}Server Setup:${NC}
   - Upload appcast_template.xml to your server as appcast.xml
   - Update the SUFeedURL in Info.plist to point to your appcast URL
   - Ensure HTTPS is used for security

${YELLOW}Important Files:${NC}
- ${BLUE}sparkle_keys/eddsa_pub.pem${NC} - Public key (safe to commit)
- ${BLUE}sparkle_keys/eddsa_priv.pem${NC} - Private key (NEVER commit!)
- ${BLUE}appcast_template.xml${NC} - Template for your update feed
- ${BLUE}sign_update.sh${NC} - Script to sign updates

${RED}Security Notes:${NC}
- Never commit the private key to version control
- Keep the private key secure and backed up
- Use HTTPS for your update server
- Verify signatures before distributing updates

EOF
}

# Main function
main() {
    log_info "Setting up Sparkle EdDSA signing for GProMail..."
    
    generate_keys
    update_info_plist  
    update_gitignore
    create_appcast_template
    create_signing_script
    
    log_success "Sparkle setup completed successfully!"
    show_instructions
}

# Check command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat << EOF
Sparkle Setup Script for gInbox

This script sets up Sparkle with modern EdDSA signing keys and 
configures the project for automatic updates.

Usage: $0

What this script does:
- Generates EdDSA signing keys for Sparkle
- Updates Info.plist with the public key  
- Creates .gitignore entries for security
- Creates appcast template and signing scripts
- Provides setup instructions

Options:
    --help, -h    Show this help message

EOF
    exit 0
fi

# Run main function
main 