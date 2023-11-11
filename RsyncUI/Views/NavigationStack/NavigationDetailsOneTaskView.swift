//
//  NavigationDetailsOneTaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct NavigationDetailsOneTaskView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @SwiftUI.Environment(EstimateProgressDetails.self) var inprogresscountmultipletask

    @Binding var selecteduuids: Set<UUID>

    @State private var gettingremotedata = true
    @State private var estimateddataonetask = Estimateddataonetask()
    @State private var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                VStack(alignment: .leading) {
                    Form {
                        if gettingremotedata == false {
                            HStack {
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

                                Spacer()

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
                    }

                    Table(outputfromrsync.output) {
                        TableColumn("") { data in
                            Text(data.line)
                        }
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

extension NavigationDetailsOneTaskView {
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
            inprogresscountmultipletask.resetcounts()
            inprogresscountmultipletask.appenduuid(selectedconfig?.id ?? UUID())
            inprogresscountmultipletask.appendrecordestimatedlist(estimateddataonetask.estimatedlistonetask[0])
        }
    }
}
