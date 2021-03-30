//
//  ContentView.swift
//  RsyncOSX
//
//  Created by Thomas Evensen on 26/12/2020.
//  Copyright © 2020 Thomas Evensen. All rights reserved.
//

import SwiftUI

struct RsyncUIView: View {
    @EnvironmentObject var rsyncversionObject: RsyncOSXViewGetRsyncversion
    @EnvironmentObject var profilenames: Profilenames

    @State private var selectedprofile: String?
    @State private var reload: Bool = false

    var body: some View {
        VStack {
            profilepicker

            Sidebar(reload: $reload, selectedprofile: $selectedprofile)
                .environmentObject(RsyncOSXdata(profile: selectedprofile))
                .environmentObject(errorhandling)
                .environmentObject(InprogressCountExecuteOneTaskDetails())
                .environmentObject(shortcutactions)
                .onChange(of: reload, perform: { _ in
                    reload = false
                })

            HStack {
                Label(rsyncversionObject.rsyncversion, systemImage: "swift")
                    .onChange(of: rsyncversionObject.rsyncversion, perform: { _ in })

                Spacer()

                JSONorPLIST.onChange(of: rsyncversionObject.rsyncversion, perform: { _ in })

                Spacer()

                Text(selectedprofile ?? NSLocalizedString("Default profile", comment: "default profile"))
            }
            .padding()
        }
        .padding()
    }

    var errorhandling: ErrorHandling {
        SharedReference.shared.errorobject = ErrorHandling()
        return SharedReference.shared.errorobject ?? ErrorHandling()
    }

    var shortcutactions: ShortcutActions {
        SharedReference.shared.shortcutobject = ShortcutActions()
        return SharedReference.shared.shortcutobject ?? ShortcutActions()
    }

    var profilepicker: some View {
        HStack {
            Picker(NSLocalizedString("Profile", comment: "default profile") + ":",
                   selection: $selectedprofile) {
                if let profiles = profilenames.profiles {
                    ForEach(profiles) { profile in
                        Text(profile.profile ?? "")
                            .tag(profile.profile)
                    }
                }
            }
            .frame(width: 200)

            Spacer()
        }
    }

    var JSONorPLIST: some View {
        HStack {
            if SharedReference.shared.json {
                Text("JSON")
                    .foregroundColor(Color.yellow)
            } else {
                Text("PLIST")
                    .foregroundColor(Color.blue)
            }
        }
    }
}
