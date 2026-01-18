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

    var changelog: String {
        Resources().getResource(resource: .changelog)
    }

    var appVersion: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "1.0"
    }

    var appBuild: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "1.0"
    }

    var copyright: String {
        let copyright = Bundle.main.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        return copyright ?? "Copyright ©2020-2026 Thomas Evensen"
    }

    var configpath: String {
        Homepath().fullpathmacserial ?? ""
    }

    var body: some View {
        Form {
            Section(header: Text("RsyncUI")
                .font(.title3)
                .fontWeight(.bold)) {
                    appnamestring

                    copyrightstring

                    HStack {
                        VStack(alignment: .leading) {
                            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .frame(width: 64, height: 64)
                            }
                        }

                        rsyncversionshortstring
                    }

                    rsyncuiconfigpathpath
                }

            Section {
                HStack {
                    ConditionalGlassButton(
                        systemImage: "doc.plaintext",
                        text: "Changelog",
                        helpText: "Changelog"
                    ) {
                        openChangelog()
                        dismiss()
                    }

                    if SharedReference.shared.newversion {
                        ConditionalGlassButton(
                            systemImage: "square.and.arrow.down.fill",
                            text: "Download",
                            helpText: "Download"
                        ) {
                            openDownload()
                        }
                    }

                    Spacer()

                    if #available(macOS 26.0, *) {
                        Button("Close", role: .close) {
                            dismiss()
                        }
                        .buttonStyle(RefinedGlassButtonStyle())
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                if SharedReference.shared.newversion {
                    Text("There is a new version available for download")
                        .font(.title3)
                        .fontWeight(.bold)
                } else {
                    Text("Changelog")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
        }
        .task {
            if SharedReference.shared.newversion {
                urlstring = await ActorGetversionofRsyncUI().downloadlinkofrsyncui() ?? ""
            }
        }
        .formStyle(.grouped)
    }

    var appnamestring: some View {
        Text("Version \(appVersion) build \(appBuild)")
    }

    var copyrightstring: some View {
        Text(copyright)
    }

    var rsyncversionshortstring: some View {
        Text(SharedReference.shared.rsyncversionshort ?? "")
    }

    var rsyncuiconfigpathpath: some View {
        Text("RsyncUI configpath: " + configpath)
    }
}

extension AboutView {
    func openChangelog() {
        if let url = URL(string: changelog) {
            NSWorkspace.shared.open(url)
        }
    }

    func openDownload() {
        if urlstring.isEmpty == false, let url = URL(string: urlstring) {
            NSWorkspace.shared.open(url)
        }
    }
}
