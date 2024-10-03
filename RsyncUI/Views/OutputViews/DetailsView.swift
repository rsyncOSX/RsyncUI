//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/06/2024.
//

import SwiftUI

struct DetailsView: View {
    let remotedatanumbers: RemoteDataNumbers

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    LabeledContent("Synchronize ID: ") {
                        if remotedatanumbers.backupID.count == 0 {
                            Text("Synchronize ID")
                                .foregroundColor(.blue)
                        } else {
                            Text(remotedatanumbers.backupID)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(-3)

                    LabeledContent("Task: ") {
                        Text(remotedatanumbers.task)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Local catalog: ") {
                        Text(remotedatanumbers.localCatalog)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Remote catalog: ") {
                        Text(remotedatanumbers.offsiteCatalog)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Server: ") {
                        if remotedatanumbers.offsiteServer.count == 0 {
                            Text("localhost")
                                .foregroundColor(.blue)
                        } else {
                            Text(remotedatanumbers.offsiteServer)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(-3)
                }
                .padding()

                VStack(alignment: .leading) {
                    LabeledContent("Total number of files: ") {
                        Text(remotedatanumbers.totalNumber)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total number of catalogs: ") {
                        Text(remotedatanumbers.totalDirs)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total numbers: ") {
                        Text(remotedatanumbers.totalNumber_totalDirs)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)

                    LabeledContent("Total bytes: ") {
                        Text(remotedatanumbers.totalNumberSizebytes)
                            .foregroundColor(.blue)
                    }
                    .padding(-3)
                }
                .padding()

                Spacer()

                if remotedatanumbers.datatosynchronize {
                    VStack(alignment: .leading) {
                        Text("^[\(remotedatanumbers.newfiles_Int) file](inflect: true) new")
                        Text("^[\(remotedatanumbers.deletefiles_Int) file](inflect: true) for delete")
                        Text("^[\(remotedatanumbers.transferredNumber_Int) file](inflect: true) changed")
                        Text("^[\(remotedatanumbers.transferredNumberSizebytes_Int) byte](inflect: true) for transfer")
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.gradient)
                    }
                    .padding()

                } else {
                    Text("No data to synchronize")
                        .font(.title2)
                        .padding()
                        .foregroundStyle(.white)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.gradient)
                        }
                        .padding()
                }
            }

            Table(remotedatanumbers.outputfromrsync ?? []) {
                TableColumn("Output from rsync") { data in
                    Text(data.line)
                }
            }
        }
    }
}
