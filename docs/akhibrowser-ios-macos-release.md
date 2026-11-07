# AkhiBrowser iOS: macOS testing and release handoff

This guide covers continuing the AkhiBrowser iOS work on a Mac. The current branch is a development build, not a
release candidate. Do not submit it to the App Store until the release blockers below are resolved.

## Get the private source and prepare the Mac

Use the private AkhiBrowser repository. Do not push Akhi-only work to the public Mozilla `origin` remote.

```sh
git clone https://github.com/halgurdh/akhibrowser-ios.git
cd akhibrowser-ios
git switch main
git pull --ff-only
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

Current protection covers main-frame domain checks and SafeSearch rewrites. It is not a full replacement for the
Akhi extension: Akhi-specific ad/resource blocking, image moderation, NoMusic, Premium, and full parental
controls/settings are not implemented here. No Safari Web Extension Xcode target is included. Safari
extension development and device testing are a separate workstream in the private `akhi-extension` repository.

## Release blockers

Resolve and document each item before creating an App Store or TestFlight release:

1. **Apple signing and entitlements.** `FirefoxApplication.entitlements` still contains Mozilla app-group and
   keychain identifiers plus browser, push-notification, Sign in with Apple, and other capabilities. Review every
   entitlement and service integration. Replace identifiers with Akhi-owned identifiers where appropriate, remove
   unused capabilities, configure the Akhi Apple Developer team and provisioning, and confirm any restricted
   entitlement is approved for the distribution account. Do not ship with Mozilla identifiers or capabilities that
   are not authorized for the Akhi app.
2. **Legal and privacy disclosures.** The app's Terms of Service URL still points to Mozilla's Firefox terms. The
   linked Akhi privacy policy must be published and accurately cover the shipped iOS app, inherited Mozilla and
   third-party services, telemetry, Sync, permissions, and filtering. Complete App Store Connect privacy disclosures
   from verified data flows; the current draft explicitly says it is not a complete release disclosure.
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

This repository is private and has a public Mozilla `origin` remote as well as the private `akhi-ios` remote. Before
any push, confirm the destination:

```sh
git remote -v
git push akhi-ios HEAD:main
```

Do not push Akhi branding, protection features, filter data, or other Akhi-exclusive implementation to `origin`.
Keep proprietary extension implementation in its designated private repository; only bring components into this app
after confirming their license and distribution rights.
