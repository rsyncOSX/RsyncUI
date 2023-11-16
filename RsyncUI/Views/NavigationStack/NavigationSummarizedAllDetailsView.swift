//
//  NavigationSummarizedAllDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct NavigationSummarizedAllDetailsView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var progressdetails: ExecuteProgressDetails
    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var path: [Tasks]

    @State private var showDetails = false

    var body: some View {
        HStack {
            Table(estimatingprogressdetails.getestimatedlist() ?? [],
                  selection: $selecteduuids)
            {
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
                let selected = (estimatingprogressdetails.getestimatedlist() ?? []).filter { _ in
                    selecteduuids.contains(selecteduuid ?? UUID())
                }
                if (selected.count) == 1 {
                    showDetails = true
                } else {
                    showDetails = false
                }
            }

            Table(estimatingprogressdetails.getestimatedlist() ?? []) {
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
        .toolbar(content: {
            ToolbarItem {
                Button {
                    path.append(Tasks(task: .executestimatedview))
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
        .onAppear {
            guard estimatingprogressdetails.estimatealltasksasync == false else {
                Logger.process.info("TasksView: estimate already in progress")
                return
            }
            /*
             if selectedconfig.config != nil {
                 let profile = selectedconfig.config?.profile ?? "Default profile"
                 if profile != rsyncUIdata.profile {
                     selecteduuids.removeAll()
                     selectedconfig.config = nil
                 }
             }
              */
            estimatingprogressdetails.resetcounts()
            progressdetails.resetcounter()
            estimatingprogressdetails.startestimateasync()
        }

        if estimatingprogressdetails.estimatealltasksasync { progressviewestimateasync }
    }

    var progressviewestimateasync: some View {
        AlertToast(displayMode: .alert, type: .loading)
            .onAppear {
                Task {
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      updateinprogresscount: estimatingprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: "")
                    await estimate.startexecution()
                }
            }
            .onDisappear {
                progressdetails.resetcounter()
                progressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
            }
    }

    var selecteduuid: Configuration.ID? {
        if (selecteduuids.count) == 1 {
            return selecteduuids.first
        } else {
            return nil
        }
    }
}

/*
 estimatedlist: estimatingprogressdetails.getestimatedlist() ?? []

 .navigationDestination(isPresented: $showDetails) {
     NavigationDetailsOneTask(selecteduuids: selecteduuids,
                              estimatedlist: estimatingprogressdetails.getestimatedlist() ?? [])
 */
