//
//  NavigationSummarizedAllDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct NavigationSummarizedAllDetailsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var selecteduuid: Set<Configuration.ID> = .init()
    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        NavigationStack {
            VStack {
                headingtitle

                HStack {
                    Table(estimatedlist, selection: $selecteduuid) {
                        TableColumn("Synchronize ID") { data in
                            if data.datatosynchronize {
                                Text(data.backupID)
                                    .foregroundColor(.blue)
                            } else {
                                Text(data.backupID)
                            }
                        }
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
                            if files.datatosynchronize {
                                Text(files.newfiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.blue)
                            } else {
                                Text(files.newfiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .width(max: 40)
                        TableColumn("Delete") { files in
                            if files.datatosynchronize {
                                Text(files.deletefiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.blue)
                            } else {
                                Text(files.deletefiles)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .width(max: 40)
                        TableColumn("Files") { files in
                            if files.datatosynchronize {
                                Text(files.transferredNumber)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.blue)
                            } else {
                                Text(files.transferredNumber)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .width(max: 40)
                        TableColumn("Bytes") { files in
                            if files.datatosynchronize {
                                Text(files.transferredNumberSizebytes)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.blue)
                            } else {
                                Text(files.transferredNumberSizebytes)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
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

                    if datatosynchronize == false {
                        Text("There seems to be no data to synchronize")
                            .font(.title2)
                    }

                    Spacer()

                    Button("Return") {}
                        .buttonStyle(ColorfulButtonStyle())
                }
            }
            .padding()
            .frame(minWidth: 1250, minHeight: 400)
        }
        .navigationDestination(for: UUID.self) { selected in
            NavigationOnetaskDetails(estimatedlist: estimatedlist, selecteduuid: selected)
        }
    }

    var headingtitle: some View {
        Text("Navigation Estimated tasks")
            .font(.title2)
            .padding()
    }

    var datatosynchronize: Bool {
        return !estimatedlist.filter { $0.datatosynchronize == true }.isEmpty
    }
}
