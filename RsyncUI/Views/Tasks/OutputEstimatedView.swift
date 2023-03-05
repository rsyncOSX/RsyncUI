//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var isPresented: Bool
    @Binding var selecteduuids: Set<UUID>
    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        VStack {
            headingtitle

            HStack {
                Table(estimatedlist) {
                    TableColumn("Synchronize ID", value: \.backupID)
                    TableColumn("Task", value: \.task)
                    TableColumn("Local catalog", value: \.localCatalog)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                    TableColumn("Server", value: \.offsiteServer)
                    TableColumn("User", value: \.offsiteUsername)
                }

                Table(estimatedlist) {
                    TableColumn("New", value: \.newfiles)
                    TableColumn("Delete", value: \.deletefiles)
                    TableColumn("Files", value: \.transferredNumber)
                    TableColumn("Bytes", value: \.transferredNumberSizebytes)
                    TableColumn("Tot num", value: \.totalNumber)
                    TableColumn("Tot bytes", value: \.totalNumberSizebytes)
                    TableColumn("Tot dir", value: \.totalDirs)
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1100, minHeight: 400)
    }

    var headingtitle: some View {
        Text("Estimated tasks")
            .font(.title2)
            .padding()
    }

    func dismissview() {
        isPresented = false
    }
}
