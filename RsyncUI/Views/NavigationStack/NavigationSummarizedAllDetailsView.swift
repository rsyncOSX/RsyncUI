//
//  NavigationSummarizedAllDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct NavigationSummarizedAllDetailsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var showview: DestinationView?
    var estimatedlist: [RemoteinfonumbersOnetask]

    @State private var selecteduuidfordetailsview = SelectedUUID()
    @State private var showDetails = false

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
                    let selected = estimatedlist.filter { estimate in
                        selecteduuids.contains(estimate.id)
                    }
                    if (selected.count) == 1 {
                        selecteduuidfordetailsview.uuid = selected[0].id
                        showDetails = true
                    } else {
                        showDetails = false
                        selecteduuidfordetailsview.uuid = nil
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
        }
        .navigationDestination(isPresented: $showDetails) {
            NavigationDetailsOneTask(estimatedlist: estimatedlist, selecteduuid: selecteduuidfordetailsview.uuid ?? UUID())
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
    }
}

@Observable
final class SelectedUUID {
    var uuid: Configuration.ID?
}
