//
//  LoadDemoDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import SwiftUI

struct LoadDemoDataView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    var body: some View {
        Text("")
    }

    var profilenames: Profilenames {
        return Profilenames()
    }

    func verifyloaddemodata() -> Bool {
        return rsyncUIdata.configurations?.count == 0 &&
            profilenames.profiles.filter { $0.profile == "DemoData" }.count == 0
    }
}
