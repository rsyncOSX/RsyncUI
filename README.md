[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues) [![Netlify Status](https://api.netlify.com/api/v1/badges/1d14d49b-ff14-4142-b135-771db071b58a/deploy-status)](https://app.netlify.com/sites/rsyncui/deploys)

The development commenced in December 2020 and RsyncUI version 1.0.0 was released 6 May 2021. RsyncUI is build for **macOS Big Sur** and later only. The name is **RsyncUI**, and because it is built for macOS Big Sur and later it will be released as a new application and not replace the current version of RsyncOSX.

There are also some SwiftUI features in code which require macOS Big Sur.

There is a [new site for info about using RsyncUI.](https://rsyncui.netlify.app)

- [the changelog](https://rsyncui.netlify.app/post/changelog/)
- info about [the development of RsyncUI](https://rsyncui.netlify.app/post/development/)

![](images/main1.png)
![](images/main2.png)

## Dependencies

RsyncUI is implemented in utilizing the SwiftUI and Combine declarative framworks, and the Swift 5.4+ language. There are though three source code dependencies:

- check for TCP connectivity by utilizing [SwiftSocket](https://github.com/swiftsocket/SwiftSocket), some functions require connections to remote servers
- execute pre and post shellscripts by utilizing John Sundell´s [ShellOut](https://github.com/JohnSundell/ShellOut)
- utilizing John Sundell´s [Files](https://github.com/JohnSundell/Files) for reading files and catalogs

All three are available as source code and automatically included as part of building RsyncOSX. There are also a copule of other sources from GitHub included as source code. Two of those are:

- [ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - RsyncUI is using [RotatingDotsIndicatorView](https://github.com/rsyncOSX/RsyncUI/blob/main/RsyncUI/Views/Modifiers/Indicators/RotatingDotsIndicatorView.swift)
- [AlertToast](https://github.com/elai950/AlertToast) - a better looking Alert for simple messages to the user

Whenever RsyncUI is throwing an error, it is presented as an SwiftUI Alert.

## Tools used

The following tools are used in development:

- Xcode 12.5 and newer, the main tool and Swift 5.4
  - a few SwiftUI features in code require latest version of Swift and macOS Big Sur (macOS 11.x)
- make to compile new versions in terminal
- [create-dmg](https://github.com/sindresorhus/create-dmg) to create new releases
- [periphery](https://github.com/peripheryapp/periphery) to identify unused code
- [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for reformatting Swift code
- [GitHub Desktop](https://desktop.github.com/) for git and GitHub

All the above tools, except Xcode and GitHub Desktop are installed by using [Homebrew](https://brew.sh/).

## Localization

RsyncUI is localized to:

- English - the base language of RsyncOSX
- German - by [Andre Voigtmann](https://github.com/andre68723)
- Norwegian - by me

Localization is done by utilizing [Crowdin](https://rsyncosx.crowdin.com/u/projects/30) to translate the xliff files which are imported into Xcode after translating. Xcode then creates the required language strings. [Crowdin is free for open source projects](https://crowdin.com/page/open-source-project-setup-request).

## Signing and notarizing

The app is signed with my Apple ID developer certificate and [notarized](https://support.apple.com/en-us/HT202491) by Apple. See [signing and notarizing](https://rsyncui.netlify.app/post/notarized/) for info. Signing and notarizing is required to run on macOS Big Sur.

## Version of rsync

RsyncUI is verified with rsync versions 2.6.9, 3.1.2, 3.1.3 and 3.2.x. Other versions of rsync will work but numbers about transferred files is not set in logs. It is recommended to [install](https://rsyncui.netlify.app/post/rsync/) the latest version of rsync.

## Application icon

The application icon is created by [Zsolt Sándor](https://github.com/graphis). All rights reserved to Zsolt Sándor.

![](icon/rsyncosx.png)
