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

            rsynclongstring

            if new.notifynewversion { notifynewversion }

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
            /*
             Text(italianstring)
                 .font(.caption)
             */
            Text(germanstring)
                .font(.caption)

            Text(norwegianstring)
                .font(.caption)
        }
        .padding()
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("New version", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            dismiss()
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

    // Dismiss the notify for new version
    func dismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            new.notifynewversion = false
        }
    }

    func opendownload() {
        if let url = SharedReference.shared.URLnewVersion {
            NSWorkspace.shared.open(URL(string: url)!)
        }
    }
}
