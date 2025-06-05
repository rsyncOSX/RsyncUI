//
//  AboutView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 28/01/2021.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss

    @State private var urlstring = ""

    let iconbystring: String = NSLocalizedString("Icon by: Zsolt Sándor", comment: "")

    var changelog: String {
        Resources().getResource(resource: .changelog)
    }

    var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "RsyncUI"
    }

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1.0"
    }

    var copyright: String {
        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return copyright ?? NSLocalizedString("Copyright ©2025 Thomas Evensen", comment: "")
    }

    var configpath: String {
        Homepath().fullpathmacserial ?? ""
    }

    var body: some View {
        Form {
            Section {
                appnamestring

                HStack {
                    VStack(alignment: .leading) {
                        Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .frame(width: 64, height: 64)

                        appicon
                    }

                    rsyncversionshortstring
                }

                rsyncuiconfigpathpath
            }

            Section {
                HStack {
                    Button {
                        openchangelog()
                        dismiss()
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .buttonStyle(ColorfulButtonStyle())

                    if SharedReference.shared.newversion {
                        Button {
                            opendownload()
                        } label: {
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                        .help("Download")
                        .buttonStyle(ColorfulButtonStyle())
                    }

                    Spacer()

                    Button("Dismiss") {
                        dismiss()
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }

            } header: {
                if SharedReference.shared.newversion {
                    Text("There is a new version available for download")

                } else {
                    Text("Changelog")
                }
            }
        }
        .task {
            urlstring = await GetversionofRsyncUI().downloadlinkofrsyncui() ?? ""
        }
        .formStyle(.grouped)
    }

    var appnamestring: some View {
        HStack(alignment: .center) {
            Text("\(appName) version \(appVersion) build \(appBuild)")
        }
        // .font(.caption)
        .padding(3)
    }

    var rsyncversionshortstring: some View {
        VStack {
            Text(SharedReference.shared.rsyncversionshort ?? "")
        }
        .font(.caption)
        .padding(3)
    }

    var rsyncuiconfigpathpath: some View {
        VStack {
            Text("RsyncUI configpath: " + configpath)
        }
        .font(.caption)
        .padding(3)
    }

    var appicon: some View {
        Text(iconbystring)
            .font(.caption)
            .padding(3)
    }
}

extension AboutView {
    func openchangelog() {
        NSWorkspace.shared.open(URL(string: changelog)!)
    }

    func opendownload() {
        if urlstring.isEmpty == false {
            NSWorkspace.shared.open(URL(string: urlstring)!)
        }
    }
}
