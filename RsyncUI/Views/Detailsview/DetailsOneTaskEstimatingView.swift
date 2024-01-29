//
//  DetailsOneTaskEstimatingView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct DetailsOneTaskEstimatingView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @State private var gettingremotedata = true
    @State private var estimatedtask: RemoteDataNumbers?
    @State private var outputfromrsync = Outputfromrsync()

    let selecteduuids: Set<SynchronizeConfiguration.ID>

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if gettingremotedata == false {
                    if let estimatedtask = estimatedtask {
                        DetailsOneTask(estimatedtask: estimatedtask)
                            .onDisappear(perform: {
                                estimateprogressdetails.appendrecordestimatedlist(estimatedtask)
                            })
                    }
                } else {
                    VStack {
                        // Only one task is estimated if selected, if more than one
                        // task is selected multiple estimation is selected. That is why
                        // that is why (uuid: selecteduuids.first)
                        if let config = rsyncUIdata.getconfig(uuid: selecteduuids.first) {
                            Text("Estimating now: " + "\(config.backupID)")
                        }

                        ProgressView()
                    }
                }
            }
        }
        .onAppear(perform: {
            var selectedconfig: SynchronizeConfiguration?
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

extension DetailsOneTaskEstimatingView {
    func processtermination(data: [String]?) {
        var selectedconfig: SynchronizeConfiguration?
        let selected = rsyncUIdata.configurations?.filter { config in
            selecteduuids.contains(config.id)
        }
        if (selected?.count ?? 0) == 1 {
            if let config = selected {
                selectedconfig = config[0]
            }
        }
        estimatedtask = RemoteDataNumbers(hiddenID: selectedconfig?.hiddenID,
                                          outputfromrsync: data,
                                          config: selectedconfig)
        gettingremotedata = false
    }
}
