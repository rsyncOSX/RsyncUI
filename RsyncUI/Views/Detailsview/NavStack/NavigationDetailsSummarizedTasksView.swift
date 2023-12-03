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
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var path: [Tasks]

    @State private var focusstartexecution: Bool = false
    @State private var nodatatosynchronize: Bool = false

    var body: some View {
        VStack {
            HStack {
                if estimatingprogressdetails.estimatealltasksasync {
                    Text("Estimating")
                } else {
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
                        guard selecteduuids.count > 0 else { return }
                        path.append(Tasks(task: .dryrunonetaskalreadyestimated))
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
            }
            .toolbar(content: {
                ToolbarItem {
                    Button {
                        path.removeAll()
                        path.append(Tasks(task: .executestimatedview))
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .foregroundColor(Color(.blue))
                    }
                    .help("Synchronize (⌘R)")
                }
            })
            .focusedSceneValue(\.startexecution, $focusstartexecution)
            .onAppear {
                guard estimatingprogressdetails.estimatealltasksasync == false else {
                    Logger.process.info("TasksView: estimate already in progress")
                    return
                }
                estimatingprogressdetails.resetcounts()
                executeprogressdetails.resetcounter()
                estimatingprogressdetails.startestimateasync()
            }

            Spacer()

            if nodatatosynchronize { shownosynchronize }
        }

        if estimatingprogressdetails.estimatealltasksasync { progressviewestimateasync }

        if focusstartexecution { labelstartexecution }
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
                executeprogressdetails.resetcounter()
                executeprogressdetails.setestimatedlist(estimatingprogressdetails.getestimatedlist())
                nodatatosynchronize = {
                    if let data = estimatingprogressdetails.getestimatedlist()?.filter({
                        $0.datatosynchronize == true })
                    {
                        return data.isEmpty
                    } else {
                        return false
                    }
                }()
            }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                path.removeAll()
                path.append(Tasks(task: .executestimatedview))
                focusstartexecution = false
            })
    }

    var shownosynchronize: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("No data to synchronize")
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear(perform: {
            // Show updated for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                nodatatosynchronize = false
            }
        })
    }
}
