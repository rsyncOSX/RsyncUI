//
//  ProfilePicker.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/01/2025.
//

import SwiftUI

struct ProfilePicker: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    // Show or hide Toolbox
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @Binding var selectedprofile: String?
    
    var body: some View {
        if columnVisibility != .detailOnly {
            Picker("", selection: $selectedprofile) {
                ForEach(profilenames.profiles ?? [], id: \.self) { profile in
                    Text(profile.profile ?? "")
                        .tag(profile.profile)
                }
            }
            .frame(width: 180)
        } else {
            VStack {
                NavigationStack {
                    List(stringprofiles, id: \.self, selection: $selectedprofile) { name in
                        Text(name)
                    }
                    .navigationTitle("Select profile")
                    .onChange(of: selectedprofile) {
                        dismiss()
                    }
                }
                
                Button("Dismiss") {
                    dismiss()
                }
                .buttonStyle(ColorfulButtonStyle())
                .padding()
            }
            .frame(width: 250, height: 300)
        }
    }

    var profilenames: Profilenames {
        Profilenames(rsyncUIdata.validprofiles ?? [])
    }

    var stringprofiles: [String] {
        if let allprofiles = profilenames.profiles {
            allprofiles.map {
                $0.profile ?? ""
            }
        } else {
            []
        }
    }
}
