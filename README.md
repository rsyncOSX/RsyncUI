## Hi there 👋

RsyncUI and RsyncOSX are GUI´s on the Apple macOS platform for the command line tool [rsync](https://github.com/WayneD/rsync). The main difference between the two apps is how the User Interface (UI) is built. It is `rsync` which executes the synchronize data tasks. The GUI´s are only for organizing tasks, setting parameters to `rsync` and make it easier to use `rsync`. 

If you are on *macOS Sonoma* use RsyncUI.

### Install by Homebrew

The apps might be installed by Homebrew or by direct Download. The apps are signed and notarized by Apple.

| App      | Homebrew | macOS |  Documentation |
| ----------- | ----------- |   ----------- |  ----------- |
| RsyncUI   | `brew install --cask rsyncui`    | macOS Sonoma and later |   [rsyncui.netlify.app](https://rsyncui.netlify.app/post/rsyncuidocs/) |
| RsyncOSX   | `brew install --cask rsyncosx`  |  macOS Big Sur and later   |  [rsyncosx.netlify.app](https://rsyncosx.netlify.app/post/rsyncosxdocs/) |

### Why two apps and latest versions

The development of RsyncOSX commenced in *2015* as a private project to learn Swift. In *2019*, Apple released SwiftUI. SwiftUI quickly became very popular and I commenced another private project, RsyncUI, to learn SwiftUI.

| App      | Storage  | #lines  | #files | UI | Latest version  |  Version 1.0.0 |
| ----------- | ----------- |   ----------- | -------- |  -------- | -------- | -------- |
| RsyncUI   | JSON  | about 11.7k | 150  | SwiftUI, declarativ     | v1.9.2 - [11 June 2024](https://github.com/rsyncOSX/RsyncUI/releases)  | 6 May 2021  |
| RsyncOSX  | JSON | about 11K | 121  | Storyboard, imperativ   | v6.8.0 - [13 April 2023](https://github.com/rsyncOSX/RsyncOSX/releases) |	14 March 2016 |

### Important to verify new tasks

The UI of RsyncUI and RsyncOSX can for users who dont know `rsync` be difficult and complex to understand. 

Setting wrong parameters to `rsync` can result in deleted data. *For your own safety* it is important to execute a simulated run, a `--dry-run`, and verify the result before the real run.

### External task executing rsync

Please be aware it is an external task *not controlled* by RsyncUI or RsyncOSX, which executes the command-line tool rsync. The progress and termination of the external rsync task are monitored. The user can abort the task at any time. Please let the abort finish and cleanup properly before starting a new task. It might take a few seconds. If not, the apps might become unresponsive.

### RsyncUI (Swift, SwiftUI) - recommended GUI

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v1.9.2/total)  [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues)

**RsyncUI** is released for **macOS Sonoma and later**. Latest build is [11 June 2024](https://github.com/rsyncOSX/RsyncUI/releases).

- the [user guide for RsyncUI](https://rsyncui.netlify.app/)
- the [changelog](https://rsyncui.netlify.app/post/changelog/)

![](images/rsyncui.png)

### RsyncOSX (Swift, Storyboard) - bugfixes only

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncOSX)](https://github.com/rsyncOSX/RsyncOSX/blob/master/Licence.MD) ![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncOSX/v6.8.0/total) [![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncOSX)](https://github.com/rsyncOSX/RsyncOSX/issues)

**RsyncOSX** is released for **macOS Big Sur** and later. Latest build is [13 April 2023](https://github.com/rsyncOSX/RsyncOSX/releases).

- the [user guide for RsyncOSX](https://rsyncosx.netlify.app/)
- the [changelog](https://rsyncosx.netlify.app/post/changelog/)

![](images/rsyncosx.png)

![My github stats](https://github-readme-stats.vercel.app/api?username=rsyncOSX&show_icons=true&hide_border=true&theme=dark)
