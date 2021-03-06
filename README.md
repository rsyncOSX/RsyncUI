[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncOSX)](https://github.com/rsyncOSX/RsyncSwiftUI/blob/master/Licence.MD)

The code is in development and may be unstable. The execution part is stable. For more info check the link below.

This is the repository of the **SwiftUI based version of RsyncOSX**, the next major release of RsyncOSX. The development commenced in December 2020 and the next release of RsyncOSX will be sometime before summer 2021. The current version of RsyncOSX is a Swift and Storyboard (View Controllers) developed macOS application. SwiftUI is a framework for UI and it replaces the Storyboards and the code for the View Controllers.

There is some more info about [the SwiftUI version](https://rsyncosx.netlify.app/post/swiftui/) and the progress.

## Dependencies

The application is implemented in pure SwiftUI and Swift. There are though three source code dependencies:

- check for TCP connectivity by utilizing [SwiftSocket](https://github.com/swiftsocket/SwiftSocket), some functions require connections to remote servers
- execute pre and post shellscripts by utilizing John Sundell´s [ShellOut](https://github.com/JohnSundell/ShellOut)
- utilizing John Sundell´s [Files](https://github.com/JohnSundell/Files) for reading files and catalogs

All three are available as source code and automatically included as part of building RsyncOSX.

## Tools used

The following tools are used in development:

- Xcode 12 (the main tool)
- make to compile new versions in terminal
- [create-dmg](https://github.com/sindresorhus/create-dmg) to create new releases
- [periphery](https://github.com/peripheryapp/periphery) to identify unused code
- [SwiftLint](https://github.com/realm/SwiftLint) to enforce Swift style and conventions
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat) for reformatting Swift code

All the above tools, except Xcode are installed by using [Homebrew](https://brew.sh/).

## Signing and notarizing

The app is signed with my Apple ID developer certificate and [notarized](https://support.apple.com/en-us/HT202491) by Apple. See [signing and notarizing](https://rsyncosx.netlify.app/post/notarized/) for info. Signing and notarizing is required to run on macOS Catalina.

## Localization

The new version will be localized. Most of the localization will be imported from the current version.

[RsyncOSX speaks new languages](https://rsyncosx.netlify.app/post/localization/). RsyncOSX is localized to:
- Chinese (Simplified) -  by [StringKe (Chen)](https://github.com/StringKe)
- German - by [Andre Voigtmann](https://github.com/andre68723)
- Norwegian - by me
- English - the base language of RsyncOSX
- Italian - by [Stefano Steve Cutelle'](https://github.com/stefanocutelle)
- Dutch - by [Marcellino Santoso](https://github.com/maebs)

Localization is done by utilizing [Crowdin](https://crowdin.com/project/rsyncosx) to translate the xliff files which are imported into Xcode after translating. Xcode then creates the required language strings. [Crowdin is free for open source projects](https://crowdin.com/page/open-source-project-setup-request).

## Version of rsync

RsyncOSX is verified with rsync versions 2.6.9, 3.1.2, 3.1.3 and 3.2.x. Other versions of rsync will work but numbers about transferred files is not set in logs. It is recommended to [install](https://rsyncosx.netlify.app/post/rsync/) the latest version of rsync.

## The source code and compile

There are [some details about source and how to compile](https://rsyncosx.netlify.app/post/compile/).

## Application icon

The application icon is created by [Zsolt Sándor](https://github.com/graphis). All rights reserved to Zsolt Sándor.

![](icon/rsyncosx.png)
