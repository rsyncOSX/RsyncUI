//
//  AboutView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 28/01/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct AboutView: View {
    @StateObject private var new = NewversionJSON()

    var iconbystring: String = NSLocalizedString("Icon by: Zsolt Sándor", comment: "icon")
    var chinesestring: String = NSLocalizedString("Chinese (Simplified) translation by: StringKe (Chen)", comment: "chinese")
    var norwegianstring: String = NSLocalizedString("Norwegian translation by: Thomas Evensen", comment: "norwegian")
    var germanstring: String = NSLocalizedString("German translation by: Andre Voigtmann", comment: "german")
    var italianstring: String = NSLocalizedString("Italian translation by: Stefano Steve Cutelle'", comment: "italian")
    var dutchstring: String = NSLocalizedString("Dutch translation by: Marcellino Santoso", comment: "ducth")

    // SwiftUI docs
    var changelog: String = "https://rsyncui.netlify.app/post/changelog/"
    // RSyncOSX docs
    var documents: String = "https://rsyncui.netlify.app/"
    /*
     // Resource strings
     var changelog: String = "https://rsyncosx.netlify.app/post/changelog/"
     var documents: String = "https://rsyncosx.netlify.app/post/rsyncosxdocs/"
     var urlplist: String = "https://raw.githubusercontent.com/rsyncOSX/RsyncOSX/master/versionRsyncOSX/versionRsyncOSX.plist"
     */
    var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "Control Room"
    }

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1.0"
    }

    var copyright: String {
        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return copyright ?? NSLocalizedString("Copyright ©2021 Thomas Evensen", comment: "copyright")
    }

    var configpath: String {
        return NamesandPaths(profileorsshrootpath: .profileroot).fullroot ?? ""
    }

    var body: some View {
        VStack {
            headingtitle

            translations

            ZStack {
                rsynclongstring

                if new.notifynewversion { notifynewversion }
            }

            buttonsview

            Text(configpath)
                .font(.caption)

        }.padding()
    }

    var headingtitle: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 64, height: 64)

            Text("RsyncUI")
                .fontWeight(.bold)

            Text("Version \(appVersion) (\(appBuild))")
                .font(.caption)

            Text(copyright)
                .font(.caption)

            Text(iconbystring)
                .font(.caption)
        }
    }

    var buttonsview: some View {
        HStack {
            Button(NSLocalizedString("Changelog", comment: "About button")) { openchangelog() }
                .buttonStyle(PrimaryButtonStyle())
            Button(NSLocalizedString("RsyncUI", comment: "About button")) { opendocumentation() }
                .buttonStyle(PrimaryButtonStyle())
            Button(NSLocalizedString("Download", comment: "About button")) { opendownload() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    var rsynclongstring: some View {
        Text(SharedReference.shared.rsyncversionstring ?? "")
            .border(Color.gray)
            .font(.caption)
    }

    var translations: some View {
        VStack {
            Text(germanstring)
                .font(.caption)

            /*
             Text(italianstring)
                 .font(.caption)
             */

            Text(norwegianstring)
                .font(.caption)
        }
        .padding()
    }

    var notifynewversion: some View {
        AlertToast(type: .complete(Color.green), title: Optional(NSLocalizedString("New version",
                                                                                   comment: "settings")), subTitle: Optional(""))
            .onAppear(perform: {
                // Show updated for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    new.notifynewversion = false
                }
            })
    }
}

extension AboutView {
    func openchangelog() {
        NSWorkspace.shared.open(URL(string: changelog)!)
    }

    func opendocumentation() {
        NSWorkspace.shared.open(URL(string: documents)!)
    }

    func opendownload() {
        if let url = SharedReference.shared.URLnewVersion {
            NSWorkspace.shared.open(URL(string: url)!)
        }
    }
}
