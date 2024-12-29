//
//  SummarizedDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct SummarizedDetailsView: View {
    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var path: [Tasks]

    @State private var focusstartexecution: Bool = false
    @State private var nodatatosynchronize: Bool = false
    @State private var isPresentingConfirm: Bool = false

    let configurations: [SynchronizeConfiguration]
    let profile: String?

    let queryitem: URLQueryItem?

    var body: some View {
        VStack {
            HStack {
                if estimateprogressdetails.estimatealltasksinprogress {
                    EstimationInProgressView(executeprogressdetails: executeprogressdetails,
                                             estimateprogressdetails: estimateprogressdetails,
                                             selecteduuids: $selecteduuids,
                                             nodatatosynchronize: $nodatatosynchronize,
                                             profile: profile,
                                             configurations: configurations)
                } else {
                    ZStack {
                        Table(estimateprogressdetails.estimatedlist ?? [],
                              selection: $selecteduuids)
                        {
                            TableColumn("Synchronize ID") { data in
                                if data.datatosynchronize {
                                    if data.backupID.isEmpty == true {
                                        Text("Synchronize ID")
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(data.backupID)
                                            .foregroundColor(.blue)
                                    }
                                } else {
                                    if data.backupID.isEmpty == true {
                                        Text("Synchronize ID")
                                    } else {
                                        Text(data.backupID)
                                    }
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
                        
                        // URL code
                        if queryitem != nil {
                            let datatosynchronize = estimateprogressdetails.estimatedlist?.filter { $0.datatosynchronize == true
                            }
                            if (datatosynchronize?.count ?? 0) > 0 {
                                TimerView(executeprogressdetails: executeprogressdetails,
                                          estimateprogressdetails: estimateprogressdetails,
                                          path: $path)
                            }
                        }
                    }

                    Table(estimateprogressdetails.estimatedlist ?? [],
                          selection: $selecteduuids)
                    {
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
                        TableColumn("kB") { files in
                            if files.datatosynchronize {
                                Text("\(files.transferredNumberSizebytes_Int / 1000)")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .foregroundColor(.blue)
                            } else {
                                Text("\(files.transferredNumberSizebytes_Int / 1000)")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .width(max: 60)
                        TableColumn("Tot num") { files in
                            Text(files.totalNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 80)
                        TableColumn("Tot kB") { files in
                            Text("\(files.totalNumberSizebytes_Int / 1000)")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 80)
                        TableColumn("Tot dir") { files in
                            Text(files.totalDirs)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 70)
                    }
                    .onChange(of: selecteduuids) {
                        guard selecteduuids.count > 0 else { return }
                        path.append(Tasks(task: .dryrunonetaskalreadyestimated))
                    }
                }
            }
            .toolbar(content: {
                let datatosynchronize = estimateprogressdetails.estimatedlist?.filter { $0.datatosynchronize == true
                }
                if (datatosynchronize?.count ?? 0) > 0 {
                    if SharedReference.shared.confirmexecute {
                        ToolbarItem {
                            Button {
                                isPresentingConfirm = estimateprogressdetails.confirmexecutetasks()
                                if isPresentingConfirm == false {
                                    executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                    path.removeAll()
                                    path.append(Tasks(task: .executestimatedview))
                                }
                            } label: {
                                Image(systemName: "play")
                                    .foregroundColor(Color(.blue))
                            }
                            .help("Synchronize (⌘R)")
                            .confirmationDialog("Synchronize tasks?",
                                                isPresented: $isPresentingConfirm)
                            {
                                Button("Synchronize", role: .destructive) {
                                    executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                    path.removeAll()
                                    path.append(Tasks(task: .executestimatedview))
                                }
                            }
                        }
                    } else {
                        ToolbarItem {
                            Button {
                                executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                                path.removeAll()
                                path.append(Tasks(task: .executestimatedview))
                            } label: {
                                Image(systemName: "play.fill")
                                    .foregroundColor(Color(.blue))
                            }
                            .help("Synchronize (⌘R)")
                        }
                    }
                }
            })
            .focusedSceneValue(\.startexecution, $focusstartexecution)
            .onAppear {
                guard estimateprogressdetails.estimatealltasksinprogress == false else {
                    Logger.process.warning("TasksView: estimate already in progress")
                    return
                }
                estimateprogressdetails.resetcounts()
                executeprogressdetails.estimatedlist = nil
                estimateprogressdetails.startestimation()
            }
        }

        Spacer()

        if focusstartexecution { labelstartexecution }
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
}
