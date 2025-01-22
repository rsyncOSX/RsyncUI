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
            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                Text(profile.profilename)
                    .tag(profile.profilename)
            }
        }
        .frame(width: 180)
    }
}
