//
//  RsyncUIView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct RsyncUIView: View {
    @State private var newversion = CheckfornewversionofRsyncUI()
    @State private var rsyncversion = Rsyncversion()
    @Binding var selectedprofile: String?

    @State private var reload: Bool = false
    @State private var start: Bool = true
    @State var selecteduuids = Set<Configuration.ID>()

    var body: some View {
        VStack {
            if start {
                VStack {
                    Text("RsyncUI a GUI for rsync")
                        .font(.largeTitle)
                    Text("https://rsyncui.netlify.app")
                        .font(.title2)
                }
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        start = false
                    }
                })

            } else {
                Sidebar(reload: $reload,
                        selectedprofile: $selectedprofile,
                        selecteduuids: $selecteduuids,
                        profilenames: profilenames,
                        errorhandling: errorhandling)
                    .environment(\.rsyncUIData, rsyncUIdata)
                    .onChange(of: reload) {
                        reload = false
                    }
            }

            HStack {
                Spacer()

                if newversion.notifynewversion { notifynewversion }

                Spacer()
            }
            .padding()
        }
        .padding()
        .task {
            await rsyncversion.getrsyncversion()
            await newversion.getversionsofrsyncui()
        }
        .toolbar(content: {
            ToolbarItem {
                profilepicker
            }
        })
    }

    var profilenames: Profilenames {
        return Profilenames()
    }

    var rsyncUIdata: RsyncUIconfigurations {
        return RsyncUIconfigurations(profile: selectedprofile, reload)
    }

    var errorhandling: AlertError {
        SharedReference.shared.errorobject = AlertError()
        return SharedReference.shared.errorobject ?? AlertError()
    }

    var profilepicker: some View {
        HStack {
            Picker("", selection: $selectedprofile) {
                ForEach(profilenames.profiles, id: \.self) { profile in
                    Text(profile.profile ?? "")
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
            .onChange(of: selectedprofile) {
                selecteduuids.removeAll()
            }
            Spacer()
        }
    }

    var notifynewversion: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("New version is available")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                newversion.notifynewversion = false
            }
        })
    }
}

extension EnvironmentValues {
    var rsyncUIData: RsyncUIconfigurations {
        get { self[RsyncUIDataKey.self] }
        set { self[RsyncUIDataKey.self] = newValue }
    }
}

private struct RsyncUIDataKey: EnvironmentKey {
    static var defaultValue: RsyncUIconfigurations = .init(profile: nil, true)
}

