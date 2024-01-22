//
//  LoadDemoDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import SwiftUI

struct LoadDemoDataView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var newdata = ObservableAddConfigurations()
    let profile: String = "DemoData"

    var body: some View {
        Button("Create") {
            loaddataandcreaterecords()
        }
    }

    func loaddataandcreaterecords() {
        guard profilenames.profiles.filter({ $0.profile == "DemoData" }).count == 0 else { return }
        newdata.createprofile(newprofile: profile)
        profilenames.update()

        let getdemodata = DemoDataJSON()

        Task {
            let configurations = await getdemodata.getconfigurations()
            let logrecords = await getdemodata.getlogrecords()

            _ = WriteConfigurationJSON(profile, configurations)
            _ = WriteLogRecordsJSON(profile, logrecords)

            selectedprofile = newdata.selectedprofile
            rsyncUIdata.profile = selectedprofile
            var hiddenIDs = Set<Int>()
            for i in 0 ..< (configurations?.count ?? 0) {
                hiddenIDs.insert(configurations?[i].hiddenID ?? -1)
            }
            rsyncUIdata.validhiddenIDs = hiddenIDs
            rsyncUIdata.configurations = configurations
        }
    }
}
