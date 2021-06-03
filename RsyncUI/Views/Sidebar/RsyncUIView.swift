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
            }

            HStack {
                Label(rsyncversionObject.rsyncversion, systemImage: "swift")

                Spacer()

                if new.notifynewversion { notifynewversion }

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
                    ForEach(profiles, id: \.self) { profile in
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
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("New version", comment: "settings"))
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
