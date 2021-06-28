//
//  AboutView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 28/01/2021.
//

import SwiftUI

struct AboutView: View {
    @EnvironmentObject var rsyncversionObject: GetRsyncversion
    @StateObject private var new = NewversionJSON()

    let iconbystring: String = "Icon by: Zsolt Sándor"
    let norwegianstring: String = "Norwegian translation by: Thomas Evensen"
    let germanstring: String = "German translation by: Andre Voigtmann"
    let changelog: String = "https://rsyncui.netlify.app/post/changelog/"

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
        return copyright ?? "Copyright ©2021 Thomas Evensen"
    }

    var configpath: String {
        return NamesandPaths(.configurations).fullpathmacserial ?? ""
    }

    var body: some View {
        VStack {
            headingtitle

            Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 64, height: 64)

            translations

            rsyncversionshortstring

            Text("RsyncUI configpath: " + configpath)
                .font(.caption)
                .padding(3)

            if new.notifynewversion { notifynewversion }

            Spacer()

            HStack {
                Spacer()

                Button("Changelog") { openchangelog() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Download") { opendownload() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
    }

    var headingtitle: some View {
        VStack(spacing: 3) {
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

    var rsyncversionshortstring: some View {
        Text(rsyncversionObject.rsyncversion)
            .font(.caption)
            .padding(3)
    }

    var translations: some View {
        VStack {
            Text(germanstring)
                .font(.caption)
            Text(norwegianstring)
                .font(.caption)
        }
        .padding(3)
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("New version")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                new.notifynewversion = false
            }
        })
    }
}

extension AboutView {
    func openchangelog() {
        NSWorkspace.shared.open(URL(string: changelog)!)
    }

    func opendownload() {
        if let url = SharedReference.shared.URLnewVersion {
            NSWorkspace.shared.open(URL(string: url)!)
        }
    }
}
