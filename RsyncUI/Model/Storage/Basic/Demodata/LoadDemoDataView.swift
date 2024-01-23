//
//  LoadDemoDataView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 22/01/2024.
//

import SwiftUI

struct LoadDemoDataView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss

    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var profilenames: Profilenames
    @Binding var selectedprofile: String?

    @State private var newdata = ObservableAddConfigurations()
    @State private var demodataexists: Bool = false
    @State private var demodataiscreataed: Bool = false

    let profile: String = "DemoData"

    var body: some View {
        VStack {
            Text("Load DemoData")
                .padding()

            HStack {
                Button("Load DemoData") { loaddataandcreaterecords() }
                    .buttonStyle(ColorfulButtonStyle())

                Button("Dismiss") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }

            if demodataexists {
                Text("Profile DemoData exists")
                    .padding()
            }

            if demodataiscreataed {
                Text("Profile DemoData is created and demodata is loaded.\n You can dimiss the view.")
                    .padding()
            }
        }
        .frame(width: 400, height: 300, alignment: .center)
    }

    func loaddataandcreaterecords() {
        guard profilenames.profiles.filter({ $0.profile == "DemoData" }).count == 0 else {
            demodataexists = true
            return
        }
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

            demodataiscreataed = true
        }
    }
}
