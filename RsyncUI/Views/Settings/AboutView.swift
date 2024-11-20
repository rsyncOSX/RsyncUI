//
//  AboutView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 28/01/2021.
//

import SwiftUI

struct AboutView: View {
    @State private var newversion = CheckfornewversionofRsyncUI()

    let iconbystring: String = NSLocalizedString("Icon by: Zsolt Sándor", comment: "")
    let norwegianstring: String = NSLocalizedString("Norwegian translation by: Thomas Evensen", comment: "")
    let germanstring: String = NSLocalizedString("German translation by: Andre Voigtmann", comment: "")
    var changelog: String {
        Resources().getResource(resource: .changelog)
    }

    /*
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
         return copyright ?? NSLocalizedString("Copyright ©2023 Thomas Evensen", comment: "")
     }
     */
    var configpath: String {
        Homepath().fullpathmacserial ?? ""
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Image(nsImage: NSImage(named: NSImage.applicationIconName)!)
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .frame(width: 64, height: 64)

                        appicon
                    }

                    translations
                }

                rsyncversionshortstring
            }

            Section {
                Button {
                    openchangelog()
                } label: {
                    Image(systemName: "doc.plaintext")
                }
                .buttonStyle(ColorfulButtonStyle())

            } header: {
                Text("Changelog")
            }

            if newversion.notifynewversion || SharedReference.shared.newversion {
                Section {
                    Button {
                        opendownload()
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                    }
                    .help("Download")
                    .buttonStyle(ColorfulButtonStyle())

                } header: {
                    Text("There is a new version available for download")
                }
            }
        }
        .task {
            await newversion.getversionsofrsyncui()
        }
        .formStyle(.grouped)
    }

    var rsyncversionshortstring: some View {
        VStack {
            Text(SharedReference.shared.rsyncversionshort ?? "")
            Text("RsyncUI configpath: " + configpath)
                .padding([.top])
        }
        .font(.caption)
        .padding(3)
    }

    var translations: some View {
        VStack(alignment: .leading) {
            Text(germanstring)
                .font(.caption)
            Text(norwegianstring)
                .font(.caption)
        }
        .padding(3)
    }

    var appicon: some View {
        Text(iconbystring)
            .font(.caption)
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
            Task {
                newversion.dismissnotify()
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
