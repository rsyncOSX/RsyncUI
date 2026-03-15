//
//  DetailsViewHeading.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2024.
//

import SwiftUI

struct DetailsViewHeading: View {
    let remotedatanumbers: RemoteDataNumbers

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    LabeledContent("Synchronize ID: ") {
                        if remotedatanumbers.backupID.count == 0 {
                            Text("Synchronize ID")
                                .foregroundStyle(.blue)
                        } else {
                            Text(remotedatanumbers.backupID)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(-3)

                    LabeledContent("Task: ") {
                        Text(remotedatanumbers.task)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Source folder: ") {
                        Text(remotedatanumbers.localCatalog)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Destination folder: ") {
                        Text(remotedatanumbers.offsiteCatalog)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Server: ") {
                        if remotedatanumbers.offsiteServer.count == 0 {
                            Text("localhost")
                                .foregroundStyle(.blue)
                        } else {
                            Text(remotedatanumbers.offsiteServer)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(-3)
                }
                .padding()

                VStack(alignment: .leading) {
                    LabeledContent("Total number of files: ") {
                        Text(remotedatanumbers.numberoffiles)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total number of catalogs: ") {
                        Text(remotedatanumbers.totaldirectories)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total numbers: ") {
                        Text(remotedatanumbers.totalnumbers)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total bytes: ") {
                        Text(remotedatanumbers.totalfilesize)
                            .foregroundStyle(.blue)
                    }
                    .padding(-3)
                }
                .padding()
            }
        }
    }
}
