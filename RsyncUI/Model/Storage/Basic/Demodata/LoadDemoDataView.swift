//
//  LoadDemoDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import SwiftUI

struct LoadDemoDataView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var newdata = ObservableAddConfigurations()
    let profile: String = "DemoData"

    var body: some View {
        Button("Create") {
            loaddataandcreaterecords()
        }
    }

    var profilenames: Profilenames {
        return Profilenames()
    }

    func loaddataandcreaterecords() {
        guard profilenames.profiles.filter({ $0.profile == "DemoData" }).count == 0 else { return }
        newdata.createprofile(newprofile: profile)

        let getdemodata = DemoDataJSON()

        Task {
            let configurations = await getdemodata.getconfigurations()
            let logrecords = await getdemodata.getlogrecords()
            _ = WriteConfigurationJSON(profile, configurations)
            _ = WriteLogRecordsJSON(profile, logrecords)

            rsyncUIdata.profile = profile
            rsyncUIdata.configurations = configurations
        }
    }
}
