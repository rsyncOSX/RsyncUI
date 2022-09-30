[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD)   ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.3.0/total) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.2.9/total) [![Netlify Status](https://api.netlify.com/api/v1/badges/1d14d49b-ff14-4142-b135-771db071b58a/deploy-status)](https://app.netlify.com/sites/rsyncui/deploys) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues)

RsyncUI is released for macOS Monterey.

- the [documentation of RsyncUI](https://rsyncui.netlify.app/)
- the [development of RsyncUI](https://rsyncui.netlify.app/post/development/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

## Dependencies

RsyncUI is implemented by utilizing the SwiftUI and Combine declarative frameworks and Swift 5. There are a few source code dependencies:

- execute pre and post shell scripts by utilizing John Sundell´s [ShellOut](https://github.com/JohnSundell/ShellOut)
- utilizing John Sundell´s [Files](https://github.com/JohnSundell/Files) for reading files and catalogs
- [ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - RsyncUI is using RotatingDotsIndicatorView
- [AlertToast](https://github.com/elai950/AlertToast) - a better looking Alert for simple messages to the user

## Tools used

The following tools are used in development:

- Xcode (the main tool)
- make to compile new versions in terminal
- [create-dmg](https://github.com/sindresorhus/create-dmg) to create new releases
- [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for reformatting Swift code

All the above, except Xcode are installed by using [Homebrew](https://brew.sh/).

## Signing and notarizing

The app is signed with my Apple ID developer certificate and notarized by Apple.

## Version of rsync

It is recommended to install the latest version of [rsync](https://rsyncui.netlify.app/post/rsync/) by Homebrew.

## Application icon

The application icon is created by [Zsolt Sándor](https://github.com/graphis). All rights reserved to Zsolt Sándor.

![](icon/rsyncosx.png)
