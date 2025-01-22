//
//  ProfilePicker.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/01/2025.
//

import SwiftUI

struct ProfilePicker: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedprofile: String?

    var body: some View {
        Picker("", selection: $selectedprofile) {
            ForEach(profilenames.profiles ?? [], id: \.self) { profile in
                Text(profile.profile ?? "")
                    .tag(profile.profile)
            }
        }
        .frame(width: 180)
    }

    var profilenames: Profilenames {
        Profilenames(rsyncUIdata.validprofiles ?? [])
    }
}
