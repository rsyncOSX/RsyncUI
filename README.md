**MacOS Sonoma** The branch `version-1.7.6-macos-sonoma` is for *macOS Sonoma, Swift 5.9* and *Xcode 15*. This branch will only compile and run on macOS Sonoma. The `main` branch will compile and run by Xcode 15 on macOS Ventura. The compiled `main` branch will execute on macOS Monterey and later including macOS Sonoma.

RsyncUI is released for macOS Monterey and later.

- the [documentation of RsyncUI](https://rsyncui.netlify.app/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

## Install by Homebrew

RsyncUI can also be installed by Homebrew: `brew install --cask rsyncui`

## Dependencies

RsyncUI is implemented by utilizing the SwiftUI, Swift and Combine declarative frameworks. There are a few source code dependencies:

- execute pre and post shell scripts by utilizing John Sundell´s [ShellOut](https://github.com/JohnSundell/ShellOut)
- utilizing John Sundell´s [Files](https://github.com/JohnSundell/Files) for reading files and catalogs
- [AlertToast](https://github.com/elai950/AlertToast) - a better looking Alert for simple messages to the user

## Tools used

The following tools are used in development:

- Xcode (the main tool)
- make to compile new versions in terminal
- [create-dmg](https://github.com/create-dmg/create-dmg) to create new releases
- [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for reformatting Swift code

All the above, except Xcode are installed by using [Homebrew](https://brew.sh/).

## Signing and notarizing

The app is signed with my Apple ID developer certificate and notarized by Apple.

## Application icon

The application icon is created by [Zsolt Sándor](https://github.com/graphis). All rights reserved to Zsolt Sándor.

![](icon/rsyncosx.png)
