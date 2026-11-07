# AkhiBrowser for iOS

AkhiBrowser for iOS is an independent browser project based on Mozilla Firefox for iOS. This repository retains upstream Firefox and Focus code and their required license notices; the Focus app is not rebranded.

The AkhiBrowser app configuration uses AkhiBrowser branding and includes on-device adult/haram domain filtering and strict SafeSearch redirects. This is a development build, not an App Store release. A Safari Web Extension target and the other Akhi extension features are not included in this build.

<table>
  <tr>
    <th style="border: none;"><strong>AkhiBrowser iOS</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-27.1-blue?logo=Xcode&logoColor=white" alt="AkhiBrowser-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-6.2-red?logo=Swift&logoColor=white" alt="AkhiBrowser-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-15.0+-green?logo=apple&logoColor=white" alt="AkhiBrowser-iOS"></td>
  </tr>
  <tr>
    <th style="border: none;"><strong>Focus iOS</strong></th>
    <td style="border: none;"><img src="https://img.shields.io/badge/Xcode-27.1-blue?logo=Xcode&logoColor=white" alt="Focus-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/Swift-6.2-red?logo=Swift&logoColor=white" alt="Focus-iOS"></td>
    <td style="border: none;"><img src="https://img.shields.io/badge/iOS-15.0+-green?logo=apple&logoColor=white" alt="Focus-iOS"></td>
  </tr>
</table>

## Building the code

This monolithic repository contains the AkhiBrowser iOS app configuration, upstream Firefox code, and the Focus iOS project.

As this is an iOS project, it is required to have Xcode on your system, and you should check that `xcode-select -p` points to `/Applications/Xcode.app/Contents/Developer` (or however you've named your `Xcode.app`).

### Automatic Installation (Recommended)
Steps: [Automated Project Setup with FXIOS](https://github.com/mozilla-mobile/firefox-ios/wiki/Automated-Project-Setup-with-FXIOS)

### Manual Installation

1. Clone the repo locally
1. For their related build instructions, please follow the respective project readmes:

- [iOS app build instructions](./firefox-ios/README.md)
- [Focus iOS](./focus-ios/README.md)

For the AkhiBrowser iOS macOS build, test, signing and release handoff, see
[the macOS release guide](./docs/akhibrowser-ios-macos-release.md).

## License

This project includes code from Firefox for iOS and Focus iOS. Keep all applicable upstream notices and comply with the licenses of each component.

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/
