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
                        .width(max: 80)
                    TableColumn("Task", value: \.task)
                        .width(max: 70)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 50, max: 150)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 50, max: 150)
                    TableColumn("Server", value: \.offsiteServer)
                        .width(min: 50, max: 100)
                    TableColumn("User", value: \.offsiteUsername)
                        .width(max: 70)
                }

                Table(estimatedlist) {
                    TableColumn("New", value: \.newfiles)
                        .width(max: 40)
                    TableColumn("Delete", value: \.deletefiles)
                        .width(max: 40)
                    TableColumn("Files", value: \.transferredNumber)
                        .width(max: 40)
                    TableColumn("Bytes", value: \.transferredNumberSizebytes)
                        .width(max: 60)
                    TableColumn("Tot num", value: \.totalNumber)
                        .width(max: 80)
                    TableColumn("Tot bytes", value: \.totalNumberSizebytes)
                        .width(max: 80)
                    TableColumn("Tot dir", value: \.totalDirs)
                        .width(max: 70)
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
        .frame(minWidth: 1200, minHeight: 400)
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
