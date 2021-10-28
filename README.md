[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.2.2/total) [![Netlify Status](https://api.netlify.com/api/v1/badges/1d14d49b-ff14-4142-b135-771db071b58a/deploy-status)](https://app.netlify.com/sites/rsyncui/deploys) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues)

RsyncUI is released for macOS Monterey.

- the [documentation of RsyncUI](https://rsyncui.netlify.app/)
- the [development of RsyncUI](https://rsyncui.netlify.app/post/development/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

## Dependencies

RsyncUI is implemented by utilizing the SwiftUI and Combine declarative frameworks, and Swift 5.5. There are though a few source code dependencies:

- execute pre and post shell scripts by utilizing John Sundell´s [ShellOut](https://github.com/JohnSundell/ShellOut)
- utilizing John Sundell´s [Files](https://github.com/JohnSundell/Files) for reading files and catalogs

They are available as source code and automatically included as part of building RsyncOSX. There are also a couple of other sources from GitHub included as source code. Two of those are:

- [ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - RsyncUI is using RotatingDotsIndicatorView
- [AlertToast](https://github.com/elai950/AlertToast) - a better looking Alert for simple messages to the user

When RsyncUI is throwing an error, it is presented as a SwiftUI Alert.

## Tools used

The following tools are used in development:

- Xcode 13, the main tool, latest version or beta of Swift and SwiftUI
- make to compile new versions in terminal
- [create-dmg](https://github.com/sindresorhus/create-dmg) to create new releases
- [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for reformatting Swift code
- [GitHub Desktop](https://desktop.github.com/) for git and GitHub

All the above tools, except Xcode and GitHub Desktop are installed by using [Homebrew](https://brew.sh/).

## Signing and notarizing

The app is signed with my Apple ID developer certificate and notarized by Apple.

## Version of rsync

RsyncUI is verified with rsync versions 2.6.9, 3.1.2, 3.1.3 and 3.2.x. Other versions of rsync will work but numbers about transferred files is not set in logs. It is recommended to [install](https://rsyncui.netlify.app/post/rsync/) the latest version of rsync.

## Application icon

The application icon is created by [Zsolt Sándor](https://github.com/graphis). All rights reserved to Zsolt Sándor.

![](icon/rsyncosx.png)
