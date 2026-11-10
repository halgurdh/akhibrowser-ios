#!/bin/sh
# Builds AkhiBrowser for iOS on a Mac with Xcode. Run from the root of the repository:
#
#   scripts/akhi-ios-build.sh simulator   build for the iOS Simulator, no Apple account needed
#   scripts/akhi-ios-build.sh test        run the site-protection tests in the Simulator
#   scripts/akhi-ios-build.sh archive     signed archive and .ipa for TestFlight (needs AkhiSigning.xcconfig)
#
# SIMULATOR picks the simulator (default: the first available iPhone).

set -eu

cd "$(dirname "$0")/.."
PROJECT=firefox-ios/Client.xcodeproj
SCHEME=Firefox
MODE="${1:-simulator}"

[ -x firefox-ios/bin/nimbus-fml.sh ] || sh ./bootstrap.sh firefox

simulator() {
    if [ -z "${SIMULATOR:-}" ]; then
        SIMULATOR=$(xcrun simctl list devices available | sed -n 's/^ *\(iPhone[^(]*\) (.*/\1/p' | head -n 1 | sed 's/ *$//')
    fi
    [ -n "$SIMULATOR" ] || { echo "No iPhone simulator: install one in Xcode, Settings, Components" >&2; exit 1; }
    echo "platform=iOS Simulator,name=$SIMULATOR"
}

case "$MODE" in
    simulator)
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
            -destination "$(simulator)" CODE_SIGNING_ALLOWED=NO build
        ;;
    test)
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" -destination "$(simulator)" \
            -only-testing:ClientTests/ContentBlockerTests test
        ;;
    archive)
        if [ ! -f firefox-ios/Client/Configuration/AkhiSigning.xcconfig ]; then
            echo "Copy firefox-ios/Client/Configuration/AkhiSigning.xcconfig.example to AkhiSigning.xcconfig" \
                "and fill in your Apple Team ID first" >&2
            exit 1
        fi
        xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
            -destination 'generic/platform=iOS' -archivePath build/AkhiBrowser.xcarchive \
            -allowProvisioningUpdates archive
        TEAM=$(sed -n 's/^AKHI_DEVELOPMENT_TEAM *= *//p' firefox-ios/Client/Configuration/AkhiSigning.xcconfig)
        cat > build/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>$TEAM</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST
        xcodebuild -exportArchive -archivePath build/AkhiBrowser.xcarchive \
            -exportOptionsPlist build/ExportOptions.plist -exportPath build/AkhiBrowser-ipa \
            -allowProvisioningUpdates
        echo "build/AkhiBrowser-ipa: upload with Xcode's Organizer or Transporter"
        ;;
    *)
        echo "Usage: $0 [simulator|test|archive]" >&2
        exit 1
        ;;
esac
