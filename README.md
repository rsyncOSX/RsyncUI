## Hi there 👋

RsyncUI is a GUI on the Apple macOS platform for the command line tool [rsync](https://github.com/WayneD/rsync). It is `rsync` which executes
the synchronize data tasks. The GUI is only for organizing tasks, setting parameters to `rsync` and make it easier to use `rsync`.

#### Install by Homebrew

RsyncUI might be installed by Homebrew or by direct Download. It is signed and notarized by Apple.

| App      | Homebrew | macOS |
| ----------- | ----------- |   ----------- |
| RsyncUI   | `brew install --cask rsyncui`    | macOS Sonoma and later |

#### External task executing rsync

Please be aware it is an external task *not controlled* by RsyncUI, which executes the command-line tool rsync. The progress and termination of the external
rsync task are monitored. The user can abort the task at any time. Please let the abort finish and cleanup properly before starting a new task.
It might take a few seconds. If not, the apps might become unresponsive.

### RsyncUI (Swift, SwiftUI)

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/blob/main/Licence.MD)
![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncUI/v2.1.6/total)
[![GitHub issues](https://img.shields.io/github/issues/rsyncOSX/RsyncUI)](https://github.com/rsyncOSX/RsyncUI/issues)

**RsyncUI** is released for *macOS Sonoma and later*. Latest build is [29 October 2024](https://github.com/rsyncOSX/RsyncUI/releases).

- the [user guide for RsyncUI](https://rsyncui.netlify.app/docs/)
- the [changelog](https://rsyncui.netlify.app/docs/changelog/)

| App      | Storage  | UI | Latest version  |
| ----------- | ----------- |   -------- | -------- |
| RsyncUI   | JSON  | SwiftUI, declarativ     | v2.1.6 - [29 October 2024](https://github.com/rsyncOSX/RsyncUI/releases) |


![](images/rsyncui.png)

### RsyncOSX (Swift, Storyboard) - archived, not maintained

[![GitHub license](https://img.shields.io/github/license/rsyncOSX/RsyncOSX_archived)](https://github.com/rsyncOSX/RsyncOSX/blob/master/Licence.MD)
![GitHub Releases](https://img.shields.io/github/downloads/rsyncosx/RsyncOSX_archived/v6.8.0/total)

**RsyncOSX** was released for *macOS Big Sur* and later. Please be aware of the repository for RsyncOSX is archived and not maintained.

| App        | UI | Latest version  |
| -----------  |   -------- | -------- |
| RsyncOSX   | Storyboard, imperativ   | v6.8.0 - [13 April 2023](https://github.com/rsyncOSX/RsyncOSX_archived/releases) - *not maintained, repository is  archived and readonly* |
