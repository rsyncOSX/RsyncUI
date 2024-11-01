//
//  GlobalChangeTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 01/11/2024.
//

import SwiftUI

struct GlobalChangeTaskView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State private var newdata = ObservableGlobalchangeConfigurations()

    var body: some View {
        HStack {
            // Column 1
            VStack(alignment: .leading) {
                VStack(alignment: .leading) { synchronizeID }

                VStack(alignment: .leading) { localandremotecatalog }

                VStack(alignment: .leading) { remoteuserandserver }
            }
            .padding()

            // Column 2
            VStack(alignment: .leading) {
                Table(configurations) {
                    TableColumn("Synchronize ID") { data in
                        if data.backupID.isEmpty == true {
                            Text("Synchronize ID")

                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 50, max: 150)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 180, max: 300)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 180, max: 300)
                    TableColumn("Remote user", value: \.offsiteUsername)
                        .width(min: 100, max: 150)
                    TableColumn("Server", value: \.offsiteServer)
                }
            }
        }
        .padding()
        .onAppear {
            newdata.globalchangedconfigurations = rsyncUIdata.configurations?.compactMap({ task in
                return (task.task != SharedReference.shared.snapshot) ? task : nil
            })
        }
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(300, NSLocalizedString("Global change local catalog", comment: ""), $newdata.localcatalog)
            EditValue(300, NSLocalizedString("Global change remote catalog", comment: ""), $newdata.remotecatalog)
        }
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, NSLocalizedString("Global change remote user", comment: ""), $newdata.remoteuser)
            // Remote server
            EditValue(300, NSLocalizedString("Global change remote server", comment: ""), $newdata.remoteserver)
        }
    }

    var synchronizeID: some View {
        Section(header: headerID) {
            // Synchronize ID
            EditValue(300, NSLocalizedString("Global change Synchronize ID", comment: ""), $newdata.backupID)
        }
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var headerID: some View {
        Text("Synchronize ID")
            .modifier(FixedTag(200, .leading))
    }

    var configurations: [SynchronizeConfiguration] {
        if let configurations = newdata.globalchangedconfigurations {
            configurations
        } else {
            []
        }
    }
}
