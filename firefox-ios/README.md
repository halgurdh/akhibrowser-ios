# AkhiBrowser for iOS

This subdirectory contains the AkhiBrowser app configuration, based on Mozilla Firefox for iOS. Upstream code and
license notices are retained; the Focus app is not rebranded.

For the macOS testing, signing and release checklist, see the [AkhiBrowser iOS release guide](../docs/akhibrowser-ios-macos-release.md).

For details on compatible Xcode and Swift versions used to build this project, as well as the minimum iOS version, refer to the root [README](../README.md).

## Building the code

1. Install the version of [Xcode](https://developer.apple.com/download/applications/) from Apple that matches what this project uses, as listed in the root [README](../README.md).
1. Node.js is required, e.g. installed via [Brew](https://brew.sh), with [n](https://github.com/tj/n#readme), or just [n-install](https://github.com/mklement0/n-install#readme) depending whether you want to use a package manager:
   ```shell
   brew install n  # or, skipping brew:  curl -L https://bit.ly/n-install | bash
   n lts
   ```
1. Clone the repository:
   ```shell
   git clone https://github.com/halgurdh/akhibrowser-ios
   ```
1. Change directories to the project root:
   ```shell
   cd akhibrowser-ios
   ```
1. From the project root, install Node.js dependencies, build user scripts and update content blocker:
   ```shell
   sh ./bootstrap.sh
   ```
1. Open the `Client.xcodeproj` under the `firefox-ios` folder in Xcode.
1. Select the `Firefox` scheme to build the AkhiBrowser configuration. The `Fennec` scheme is the upstream development configuration.
1. Select the destination device you want to build on.
1. Run the app with `Cmd + R` or by pressing the `build and run` button.
1. On your first build in Xcode, you may be asked to approve the `ModifiedCopy` Swift macro. Click `Trust & Enable` to let the build continue. This is expected, and the prompt comes back if the macro package changes.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:

- Xcode -> File -> Packages -> Reset Package Caches

## Building User Scripts

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated, and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```none
/Client
|-- /Frontend
    |-- /UserContent
        |-- /UserScripts
            |-- /AllFrames
            |   |-- /AtDocumentEnd
            |   |-- /AtDocumentStart
            |-- /MainFrame
                |-- /AtDocumentEnd
                |-- /AtDocumentStart
```

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and is named accordingly:

- `AllFramesAtDocumentEnd.js`
- `AllFramesAtDocumentStart.js`
- `MainFrameAtDocumentEnd.js`
- `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository.

To start a watcher that will compile the User Scripts on save, run the following `npm` command in the root directory of the project:

```shell
npm run dev
```

⚠️ Note: `npm run dev` will build the JS bundles in development mode with source maps, which allows tracking down lines in the source code for debugging.

To create a production build of the User Scripts, run the following `npm` command in the root directory of the project:

```shell
npm run build
```

## Updating License Acknowledgements

In the app, the Settings > Licenses screen credits open source packages we use to build Firefox for iOS. 

If you add a new third party package or resource, please update the credits. Follow the instructions in our `license_plist_config.yml` file.
