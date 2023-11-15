//
//  NavigationSummarizedAllDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

@available(macOS 14.0, *)
struct NavigationSummarizedAllDetailsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var showview: DestinationView?
    @State private var showDetails = false

    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        NavigationStack {
            HStack {
                Table(estimatedlist, selection: $selecteduuids) {
                    TableColumn("Synchronize ID") { data in
                        if data.datatosynchronize {
                            Text(data.backupID)
                                .foregroundColor(.blue)
                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 40, max: 80)
                    TableColumn("Task", value: \.task)
                        .width(max: 60)
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
                    .width(max: 60)
                }
                .onChange(of: selecteduuids) {
                    let selected = estimatedlist.filter { _ in
                        selecteduuids.contains(selecteduuid ?? UUID())
                    }
                    if (selected.count) == 1 {
                        showDetails = true
                    } else {
                        showDetails = false
                    }
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

            if datatosynchronize == false {
                Text("There seems to be no data to synchronize")
                    .font(.title2)
            }
        }
        .navigationDestination(isPresented: $showDetails) {
            NavigationDetailsOneTask(selecteduuids: selecteduuids, estimatedlist: estimatedlist)
        }
        .toolbar(content: {
            ToolbarItem {
                Button {
                    showview = .executestimatedview
                } label: {
                    Image(systemName: "arrowshape.turn.up.backward")
                }
                .help("Execute (⌘R)")
            }
        })
        .onChange(of: selecteduuids) {
            if selecteduuid != nil {
                showDetails = true
            } else {
                showDetails = false
            }
        }
    }

    var selecteduuid: Configuration.ID? {
        if (selecteduuids.count) == 1 {
            return selecteduuids.first
        } else {
            return nil
        }
    }

    var datatosynchronize: Bool {
        return !estimatedlist.filter { $0.datatosynchronize == true }.isEmpty
    }
}
