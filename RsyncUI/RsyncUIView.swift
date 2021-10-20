//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct RsyncUIView: View {
    @EnvironmentObject var rsyncversionObject: GetRsyncversion
    @EnvironmentObject var checkfornewversionofrsyncui: NewversionJSON

    @StateObject var profilenames = Profilenames()
    @Binding var selectedprofile: String?
    @State private var reload: Bool = false
    @State private var searchText = ""

    var body: some View {
        VStack {
            profilepicker

            ZStack {
                Sidebar(reload: $reload, selectedprofile: $selectedprofile)
                    .environmentObject(rsyncUIdata)
                    .environmentObject(errorhandling)
                    .environmentObject(InprogressCountExecuteOneTaskDetails())
                    .environmentObject(profilenames)
                    .onChange(of: reload, perform: { _ in
                        reload = false
                    })
            }

            HStack {
                Spacer()

                if checkfornewversionofrsyncui.notifynewversion { notifynewversion }

                Spacer()
            }
            .padding()
        }
        .padding()
        .searchable(text: $searchText)
        .task {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                rsyncversionObject.update(SharedReference.shared.rsyncversion3)
            }
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
            Picker("", selection: $selectedprofile) {
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
                checkfornewversionofrsyncui.notifynewversion = false
            }
        })
    }
}
