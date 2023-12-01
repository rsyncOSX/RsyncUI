This branch is for **macOS Sonoma**, Swift 5.9 and Xcode 15. It will only compile and run on macOS Sonoma. The major work in this branch is migrating objects and bindings to the new `@Observable` macro introduced in Swift 5.9, Xcode 15 and macOS Sonoma. Migrating code to the new macro is a *breaking change* and that is why there are two builds.  

- the [documentation of RsyncUI](https://rsyncui.netlify.app/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

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
