//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var selecteduuids: Set<UUID>
    @Binding var execute: Bool
    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        VStack {
            headingtitle

            HStack {
                Table(estimatedlist) {
                    TableColumn("Synchronize ID", value: \.backupID)
                        .width(min: 80, max: 200)
                    TableColumn("Task", value: \.task)
                        .width(max: 80)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Server") { data in
                        if data.offsiteServer.count > 0 {
                            Text(data.offsiteServer)
                        } else {
                            Text("localhost")
                        }
                    }
                    .width(max: 80)
                }

                Table(estimatedlist) {
                    TableColumn("New") { files in
                        Text(files.newfiles)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 40)
                    TableColumn("Delete") { files in
                        Text(files.deletefiles)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 40)
                    TableColumn("Files") { files in
                        Text(files.transferredNumber)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 40)
                    TableColumn("Bytes") { files in
                        Text(files.transferredNumberSizebytes)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 60)
                    TableColumn("Tot num") { files in
                        Text(files.totalNumber)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 80)
                    TableColumn("Tot bytes") { files in
                        Text(files.totalNumberSizebytes)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 80)
                    TableColumn("Tot dir") { files in
                        Text(files.totalDirs)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .width(max: 70)
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Execute") {
                    execute = true
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1250, minHeight: 400)
    }

    var headingtitle: some View {
        Text("Estimated tasks")
            .font(.title2)
            .padding()
    }
}
