//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct RsyncUIView: View {
    @StateObject var rsyncversion = Rsyncversion()
    @StateObject var profilenames = Profilenames()
    @StateObject var newversion = CheckfornewversionofRsyncUI()
    @StateObject var inprogresscountexecuteonetaskdetails = InprogressCountExecuteOneTaskDetails()

    @Binding var selectedprofile: String?
    @State private var reload: Bool = false
    @State private var defaultprofile = "Default profile"
    @State private var timerisenabled: Bool = false

    // Initial view in tasks
    @State private var selection: NavigationItem? = Optional.none

    var body: some View {
        VStack {
            if profilenames.profiles?.count == 0 {
                defaultprofilepicker
            } else {
                profilepicker
            }

            Sidebar(reload: $reload,
                    selectedprofile: $selectedprofile,
                    selection: $selection,
                    timerisenabled: $timerisenabled)
                .environmentObject(rsyncUIdata)
                .environmentObject(errorhandling)
                .environmentObject(inprogresscountexecuteonetaskdetails)
                .environmentObject(profilenames)
                .onChange(of: reload, perform: { _ in
                    reload = false
                })

            HStack {
                Spacer()

                if newversion.notifynewversion { notifynewversion }

                Spacer()
            }
            .padding()
        }
        .padding()
        .task {
            // DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            selection = .tasksview
            // }
            await rsyncversion.getrsyncversion()
            await newversion.getversionsofrsyncui()
        }
    }

    var rsyncUIdata: RsyncUIconfigurations {
        return RsyncUIconfigurations(profile: selectedprofile)
    }

    var errorhandling: ErrorHandling {
        SharedReference.shared.errorobject = ErrorHandling()
        return SharedReference.shared.errorobject ?? ErrorHandling()
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile.onChange {
                timerisenabled = false
            }) {
                if let profiles = profilenames.profiles {
                    ForEach(profiles, id: \.self) { profile in
                        Text(profile.profile ?? "")
                            .tag(profile.profile)
                    }
                }
            }
            .frame(width: 180)
            .accentColor(.blue)

            Spacer()
        }
    }

    var defaultprofilepicker: some View {
        HStack {
            Picker("", selection: $defaultprofile) {
                Text("Default profile")
                    .tag("Default profile")
            }
            .frame(width: 180)
            .accentColor(.blue)

            Spacer()
        }
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
            // Show updated for 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                newversion.notifynewversion = false
            }
        })
    }
}
