# GProMail Sparkle Update System Setup

## ✅ What's Already Done

1. **App Configuration**: Updated `Info.plist` with correct appcast URL
2. **EdDSA Keys**: Generated and configured modern Sparkle signing keys
3. **Appcast File**: Created `appcast.xml` with proper structure
4. **Update Script**: Created `update_appcast.sh` for automated signing

## 🔧 Setup Steps Required

### 1. Enable GitHub Pages

1. Go to your repository: https://github.com/bunnysayzz/GProMail
2. Click **Settings** tab
3. Scroll down to **Pages** section
4. Under **Source**, select **Deploy from a branch**
5. Choose **main** branch and **/ (root)** folder
6. Click **Save**

### 2. Create a GitHub Release

1. Go to **Releases** tab in your repository
2. Click **Create a new release**
3. Set **Tag version**: `v0.2.3`
4. Set **Release title**: `GProMail 0.2.3`
5. Upload the DMG file: `GProMail-0.2.3.dmg`
6. Add release notes describing the changes
7. Click **Publish release**

### 3. Test the Update System

1. **Wait 5-10 minutes** for GitHub Pages to deploy
2. **Open your GProMail app**
3. **Go to GProMail menu → Check for Updates...**
4. The update should now be clickable and functional!

## 📁 Files Created

- `appcast.xml` - The update feed file
- `update_appcast.sh` - Script to sign DMG files and update appcast
- `docs/index.html` - GitHub Pages redirect
- `sparkle_keys/` - Your EdDSA signing keys

## 🔄 For Future Updates

When you release a new version:

1. **Build your app** and create a new DMG
2. **Run the update script**: `./update_appcast.sh`
3. **Commit and push** the updated appcast: `git add appcast.xml && git commit -m "Update appcast for vX.X.X" && git push`
4. **Create a GitHub release** with the new DMG file
5. **Users will get the update** automatically!

## 🔍 Troubleshooting

### "Check for Updates" is grayed out
- Make sure GitHub Pages is enabled
- Wait 5-10 minutes for deployment
- Check the appcast URL is accessible: https://bunnysayzz.github.io/GProMail/appcast.xml

### Update fails to download
- Verify the DMG file is uploaded to GitHub releases
- Check the URL in appcast.xml matches your release
- Ensure the EdDSA signature is correct

### App crashes on update check
- Verify Sparkle framework is properly linked
- Check that EdDSA public key is included in app bundle

## 🎯 Current Status

- ✅ App builds and runs without crashes
- ✅ Sparkle framework loads properly
- ✅ EdDSA keys configured
- ✅ Appcast file created and signed
- ⏳ GitHub Pages setup (manual step required)
- ⏳ GitHub release creation (manual step required)

Once you complete the manual steps above, your update system will be fully functional! 