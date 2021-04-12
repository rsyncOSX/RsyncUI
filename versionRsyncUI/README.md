
## versionRsyncOSX.plist

The file `versionRsyncOSX.plist` is checked (in a asynchron background que) by RsyncOSX at every startup. The file is hosted on Github (see [resources.swift](https://github.com/rsyncOSX/Version3.x/blob/master/RsyncOSXver30/Resources.swift)). The content of URL is `version number` and link to new `RsyncOSX.dmg` file. At startup RsyncOSX checks its version number compared to version numbers listed in URL. If there is a match between RsyncOSX version number and URL there is released a newer version of RsyncOSX.

