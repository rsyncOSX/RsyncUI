//
//  SummarizedDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import OSLog
import SwiftUI

struct SummarizedDetailsView: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]

    @State private var focusstartexecution: Bool = false
    @State private var isPresentingConfirm: Bool = false

    let configurations: [SynchronizeConfiguration]
    let profile: String?
    // URL code
    let queryitem: URLQueryItem?

    var body: some View {
        VStack {
            HStack {
                if progressdetails.estimatealltasksinprogress {
                    EstimationInProgressView(progressdetails: progressdetails,
                                             selecteduuids: $selecteduuids,
                                             profile: profile,
                                             configurations: configurations)
                        .onDisappear {
                            let datatosynchronize = progressdetails.estimatedlist?.compactMap { element in
                                element.datatosynchronize ? true : nil
                            }
                            if let datatosynchronize {
                                if datatosynchronize.count == 0,
                                   SharedReference.shared.alwaysshowestimateddetailsview == false
                                {
                                    executetaskpath.removeAll()
                                }
                            }
                        }
                } else {
                    ZStack {
                        HStack {
                            leftcolumndetails

                            rightcolumndetails
                        }

                        if datatosynchronize {
                            if SharedReference.shared.confirmexecute {
                                Button {
                                    isPresentingConfirm = progressdetails.confirmexecutetasks()
                                    if isPresentingConfirm == false {
                                        executetaskpath.removeAll()
                                        executetaskpath.append(Tasks(task: .executestimatedview))
                                    }
                                } label: {
                                    Text(Image(systemName: "play.fill"))
                                        // .foregroundColor(.blue)
                                        .font(.title2)
                                        .imageScale(.large)
                                }
                                .buttonStyle(.borderedProminent)
                                .help("Synchronize (⌘R)")
                                // .buttonStyle(ColorfulButtonStyle())
                                .confirmationDialog("Synchronize tasks?",
                                                    isPresented: $isPresentingConfirm)
                                {
                                    Button("Synchronize", role: .destructive) {
                                        executetaskpath.removeAll()
                                        executetaskpath.append(Tasks(task: .executestimatedview))
                                    }
                                }

                            } else {
                                Button {
                                    executetaskpath.removeAll()
                                    executetaskpath.append(Tasks(task: .executestimatedview))
                                } label: {
                                    Text(Image(systemName: "play.fill"))
                                        .imageScale(.large)
                                        // .foregroundColor(.blue)
                                        .font(.title2)
                                }
                                .help("Synchronize (⌘R)")
                                .buttonStyle(.borderedProminent)
                                // .buttonStyle(ColorfulButtonStyle())
                            }
                        }
                    }
                }
            }
            .toolbar(content: {
                if datatosynchronizeURL {
                    ToolbarItem {
                        TimerView(executetaskpath: $executetaskpath)
                    }

                    ToolbarItem {
                        Spacer()
                    }
                }
            })
            .frame(maxWidth: .infinity)
            .focusedSceneValue(\.startexecution, $focusstartexecution)
            .onAppear {
                guard progressdetails.estimatealltasksinprogress == false else {
                    Logger.process.warning("SummarizedDetailsView: estimate already in progress")
                    return
                }
                progressdetails.resetcounts()
                progressdetails.startestimation()
            }
        }

        Spacer()

        if focusstartexecution { labelstartexecution }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear {
                executetaskpath.removeAll()
                executetaskpath.append(Tasks(task: .executestimatedview))
                focusstartexecution = false
            }
    }

    // URL code
    var datatosynchronizeURL: Bool {
        if queryitem != nil, progressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = progressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    var datatosynchronize: Bool {
        if queryitem == nil, progressdetails.estimatealltasksinprogress == false {
            let datatosynchronize = progressdetails.estimatedlist?.filter { $0.datatosynchronize == true }
            if (datatosynchronize?.count ?? 0) > 0 {
                return true
            } else {
                return false
            }
        }
        return false
    }

    var leftcolumndetails: some View {
        Table(progressdetails.estimatedlist ?? [],
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
            .width(min: 80, max: 120)
            TableColumn("Source folder", value: \.localCatalog)
                .width(min: 100, max: 250)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(max: 100)
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
    }

    var rightcolumndetails: some View {
        Table(progressdetails.estimatedlist ?? [],
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
            TableColumn("Updates") { files in
                if files.datatosynchronize {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.blue)
                } else {
                    Text(files.filestransferred)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(max: 55)
            TableColumn("kB trans") { files in
                if files.datatosynchronize {
                    Text("\(files.totaltransferredfilessize_Int / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundColor(.blue)
                } else {
                    Text("\(files.totaltransferredfilessize_Int / 1000)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(max: 100)
            TableColumn("Tot files") { files in
                Text(files.numberoffiles)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 90)
            TableColumn("Tot kB") { files in
                Text("\(files.totalfilesize_Int / 1000)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 80)
            TableColumn("Tot cat") { files in
                Text(files.totaldirectories)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(max: 70)
        }
        .onChange(of: selecteduuids) {
            guard selecteduuids.count > 0 else { return }
            executetaskpath.append(Tasks(task: .dryrunonetaskalreadyestimated))
        }
    }
}
