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
    @StateObject private var new = NewversionJSON()

    var body: some View {
        VStack {
            profilepicker

            ZStack {
                Sidebar(reload: $reload, selectedprofile: $selectedprofile)
                    .environmentObject(RsyncUIdata(profile: selectedprofile))
                    .environmentObject(errorhandling)
                    .environmentObject(InprogressCountExecuteOneTaskDetails())
                    .onChange(of: reload, perform: { _ in
                        reload = false
                    })

                if new.notifynewversion { notifynewversion }
            }

            HStack {
                Label(rsyncversionObject.rsyncversion, systemImage: "swift")
                    .onChange(of: rsyncversionObject.rsyncversion, perform: { _ in })

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

    var notifynewversion: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("New version",
                                                     comment: "settings")),
                   subTitle: Optional(""))
            .onAppear(perform: {
                // Show updated for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    new.notifynewversion = false
                }
            })
    }
}
