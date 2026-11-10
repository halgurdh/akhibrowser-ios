# AkhiBrowser iOS: macOS testing and release handoff

This guide covers continuing the AkhiBrowser iOS work on a Mac. The current branch is a development build, not a
release candidate. Do not submit it to the App Store until the release blockers below are resolved.

## Get the source and prepare the Mac

This repository is public. The protections come from the private `akhi-extension` repository, a submodule at
`akhi-extension/` (AkhiKit, in its `ios/` folder): cloning it needs a GitHub account with access to it.

```sh
git clone --recurse-submodules https://github.com/halgurdh/akhibrowser-ios.git
cd akhibrowser-ios
```

Install the Xcode version required by the repository's root [README](../README.md), open Xcode once to accept its
license, and install an iOS Simulator runtime. Install the Node.js version required by the Firefox iOS build
instructions, then bootstrap the repository:

```sh
xcode-select -p
xcodebuild -version
xcrun simctl list devices available
sh ./bootstrap.sh
```

Open `firefox-ios/Client.xcodeproj` and select the shared `Firefox` scheme. In this repository that scheme uses
`Firefox.xcconfig`, which selects the AkhiBrowser display name, bundle identifier, and app icon. `Fennec` is the
upstream development scheme and is not the AkhiBrowser app configuration.

## Signing with the Akhi Apple Developer account

The `Firefox` configuration (the AkhiBrowser app, its extensions and widgets) uses automatic signing with the Akhi
team, never Mozilla's. Its identifiers: the app `org.akhibrowser.ios`, extensions `org.akhibrowser.ios.<name>`, app
group `group.org.akhibrowser.ios`, keychain group `<Team ID>.org.akhibrowser.ios`. The app derives the app group and
keychain group from its bundle identifier, so the entitlements must keep matching it.

```sh
cp firefox-ios/Client/Configuration/AkhiSigning.xcconfig.example firefox-ios/Client/Configuration/AkhiSigning.xcconfig
# then put the Team ID from developer.apple.com/account (Membership details) in it
```

`AkhiSigning.xcconfig` is ignored by git. Simulator builds need no Team ID. With one, Xcode registers the identifiers
and app group and makes the profiles itself (Xcode, Settings, Accounts: sign in with the Akhi Apple ID once).

The entitlements `com.apple.developer.web-browser` (being chosen as default browser) and
`com.apple.developer.browser.app-installation` were removed: Apple grants them only on request, and automatic signing
fails while they are listed. Request the default browser entitlement from Apple for `org.akhibrowser.ios`, and once it
is granted add it back to `firefox-ios/Client/Entitlements/FirefoxApplication.entitlements`.

## Build in one command

```sh
scripts/akhi-ios-build.sh simulator   # build for the Simulator
scripts/akhi-ios-build.sh test        # site-protection tests (see below about skipped tests)
scripts/akhi-ios-build.sh archive     # signed archive and .ipa for TestFlight
```

## Xcode Cloud

`firefox-ios/ci_scripts/ci_post_clone.sh` runs the bootstrap on Xcode Cloud. Once, on a Mac: open
`firefox-ios/Client.xcodeproj`, Product, Xcode Cloud, Create Workflow, choose the `Firefox` scheme and grant access to
the `halgurdh/akhibrowser-ios` repository. In the workflow's Environment, add the variable `AKHI_DEVELOPMENT_TEAM` with
the Team ID. An Archive action with TestFlight deployment then uploads each build. 25 compute hours a month are
included with the developer membership.

## Build and test in Simulator

Choose a simulator name and iOS version shown by `xcrun simctl list devices available`, then substitute it below:

```sh
xcodebuild \
  -project firefox-ios/Client.xcodeproj \
  -scheme Firefox \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build
```

Run the focused site-protection tests:

```sh
xcodebuild \
  -project firefox-ios/Client.xcodeproj \
  -scheme Firefox \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ClientTests/ContentBlockerTests \
  test
```

The shared `UnitTest` plan currently lists `ContentBlockerTests` among skipped tests. If Xcode reports that the tests
were skipped, open the scheme's Test action, select the `UnitTest` plan, remove `ContentBlockerTests` from that
plan's **Skipped Tests**, and rerun. Do not treat a successful test command with zero executed tests as validation.

Before sharing a build, also run the existing unit and smoke-test plans using Xcode's Test action. Confirm the test
destination and plan are available in the installed Xcode version; use the repository's
[Xcode upgrade guide](./xcode-upgrade.md) for the established `xcodebuild` test conventions.

## Manual checks on Simulator and a real iPhone

After automated tests pass, check at least:

- The installed app name and icon say AkhiBrowser; onboarding, permissions and Settings open the intended policy
  links.
- A listed adult domain and a subdomain are blocked on top-level navigation, an ordinary domain is not blocked, and
  the block alert is understandable and dismissible with VoiceOver.
- Google, Bing, DuckDuckGo and Yahoo searches use strict SafeSearch without redirect loops; unrelated URLs and
  non-search pages are not rewritten.
- Reload, back/forward, redirects, private tabs, external links, and pages with embedded frames behave as expected.
- Filtering works with missing or malformed filter assets failing visibly in logs; confirm the app does not silently
  claim protection is active when filter data cannot load.
- On a real iPhone, signing, install, startup, navigation, memory use, and app lifecycle work on the minimum and
  current supported iOS versions.

Current protection, from AkhiKit: adult, haram and scam sites and their subdomains on main-frame loads (scam with
"continue anyway"), blocked searches in 11 languages with a haram search turned into a question, SafeSearch on Google,
Bing, DuckDuckGo and Yahoo, YouTube Restricted Mode, and the block texts in 12 languages. AkhiKit runs the extension's
own `lib/content_filter.js` and `lib/search_filter.js` with its `filters/*.bin`, so the decisions match the browser on
Windows and Android. Not yet: ad blocking, image moderation, NoMusic, Premium and parental controls.

## Release blockers

Resolve and document each item before creating an App Store or TestFlight release:

1. **Apple signing and entitlements.** Done: Akhi identifiers, automatic signing with the Akhi team, and the
   entitlements Apple grants only on request removed (see Signing above). Still to do: request the default browser
   entitlement; decide whether push notifications, Sign in with Apple and the password AutoFill extension stay, as they
   came with Firefox's account and Sync services.
2. **Legal and privacy disclosures.** No AkhiBrowser Terms page is published yet, so the onboarding screen no longer
   links to Mozilla's Firefox terms or claims acceptance of them. Publish and review AkhiBrowser terms before
   presenting a terms link or making a release that requires them. The privacy link goes to the Akhi site, but its
   policy must accurately cover the shipped iOS app, inherited Mozilla and third-party services, telemetry, Sync,
   permissions, and filtering. Complete App Store Connect privacy disclosures from verified data flows; the current
   policy does not yet provide a complete iOS release disclosure.
3. **Product readiness.** Decide whether the App Store product is the current native browser only or also includes a
   separately delivered Safari Web Extension. Implement and test any promised features; do not describe prototype or
   unimplemented extension features as available.
4. **Licensing and attribution.** Keep all MPL and third-party notices. Review the license screen and source
   attributions whenever filter data or other upstream components change.
5. **Release verification.** Run the full applicable test plans, review App Store screenshots and metadata, test a
   signed archive on real devices, verify upgrade/data-migration behavior, and use TestFlight before requesting
   App Review.

## Archive and TestFlight

Only after the release blockers are closed, configure signing in Xcode with the Akhi Developer team and verify the
resolved bundle identifier, entitlements, privacy policy, and App Store Connect record. Archive the `Firefox` scheme
for a generic iOS device:

```sh
xcodebuild \
  -project firefox-ios/Client.xcodeproj \
  -scheme Firefox \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/AkhiBrowser.xcarchive \
  archive
```

Validate the archive and signing in Xcode Organizer, then upload it to App Store Connect for internal TestFlight
testing. Use the same verified archive for later submission; do not distribute an unsigned or locally ad-hoc build as
an App Store release.

## Keep Akhi-only work private

This repository is public, so anyone can read it. Code, lists and features that are AkhiBrowser's own go into
`akhi-extension` (AkhiKit) or `akhibrowser-premium`, never into this repository; changes here stay small hooks into
Firefox's files, which are MPL and public anyway. The GitHub build of this repository puts an app with AkhiKit only in
a private draft release of `akhi-extension`, never in a public artifact.
