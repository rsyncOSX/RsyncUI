//
//  NavigationDetailsOneTaskRootView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct NavigationDetailsOneTaskRootView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @State private var gettingremotedata = true

    @State private var estimateddataonetask = Estimateddataonetask()
    @State private var outputfromrsync = Outputfromrsync()

    let selecteduuids: Set<Configuration.ID>

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if gettingremotedata == false {
                    HStack {
                        Form {
                            VStack(alignment: .leading) {
                                LabeledContent("Synchronize ID: ") {
                                    if estimateddataonetask.estimatedlistonetask[0].backupID.count == 0 {
                                        Text("Synchronize ID")
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(estimateddataonetask.estimatedlistonetask[0].backupID)
                                            .foregroundColor(.blue)
                                    }
                                }
                                LabeledContent("Task: ") {
                                    Text(estimateddataonetask.estimatedlistonetask[0].task)
                                        .foregroundColor(.blue)
                                }
                                LabeledContent("Local catalog: ") {
                                    Text(estimateddataonetask.estimatedlistonetask[0].localCatalog)
                                        .foregroundColor(.blue)
                                }
                                LabeledContent("Remote catalog: ") {
                                    Text(estimateddataonetask.estimatedlistonetask[0].offsiteCatalog)
                                        .foregroundColor(.blue)
                                }
                                LabeledContent("Server: ") {
                                    if estimateddataonetask.estimatedlistonetask[0].offsiteServer.count == 0 {
                                        Text("localhost")
                                            .foregroundColor(.blue)
                                    } else {
                                        Text(estimateddataonetask.estimatedlistonetask[0].offsiteServer)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .padding()

                        Form {
                            HStack {
                                VStack(alignment: .trailing) {
                                    LabeledContent("New: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].newfiles)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Delete: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].deletefiles)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Files: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].transferredNumber)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Bytes: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].transferredNumberSizebytes)
                                            .foregroundColor(.blue)
                                    }
                                }

                                VStack(alignment: .trailing) {
                                    LabeledContent("Tot num: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalNumber)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Tot bytes: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalNumberSizebytes)
                                            .foregroundColor(.blue)
                                    }
                                    LabeledContent("Tot dir: ") {
                                        Text(estimateddataonetask.estimatedlistonetask[0].totalDirs)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }

            ZStack {
                Table(outputfromrsync.output) {
                    TableColumn("") { data in
                        Text(data.line)
                    }
                }

                if gettingremotedata { AlertToast(displayMode: .alert, type: .loading) }
            }
        }
        .onAppear(perform: {
            var selectedconfig: Configuration?
            let selected = rsyncUIdata.configurations?.filter { config in
                selecteduuids.contains(config.id)
            }
            if (selected?.count ?? 0) == 1 {
                if let config = selected {
                    selectedconfig = config[0]
                }
            }
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }
            let task = RsyncAsync(arguments: arguments,
                                  processtermination: processtermination)
            Task {
                await task.executeProcess()
            }
        })
    }
}

extension NavigationDetailsOneTaskRootView {
    func processtermination(data: [String]?) {
        var selectedconfig: Configuration?
        let selected = rsyncUIdata.configurations?.filter { config in
            selecteduuids.contains(config.id)
        }
        if (selected?.count ?? 0) == 1 {
            if let config = selected {
                selectedconfig = config[0]
            }
        }
        outputfromrsync.generatedata(data)
        estimateddataonetask.update(data: data, hiddenID: selectedconfig?.hiddenID, config: selectedconfig)
        gettingremotedata = false
        // Adding computed estimate if later execute and view of progress
        if estimateddataonetask.estimatedlistonetask.count == 1 {
            estimateprogressdetails.resetcounts()
            estimateprogressdetails.appenduuid(selectedconfig?.id ?? UUID())
            estimateprogressdetails.appendrecordestimatedlist(estimateddataonetask.estimatedlistonetask[0])
            estimateprogressdetails.setprofileandnumberofconfigurations(rsyncUIdata.profile ?? "Default profile",
                                                                        rsyncUIdata.getallconfigurations()?.count ?? 0)
        }
    }
}
