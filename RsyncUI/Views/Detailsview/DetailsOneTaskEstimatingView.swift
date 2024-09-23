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
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @State private var gettingremotedata = true
    @State private var estimatedtask: RemoteDataNumbers?

    let selecteduuids: Set<SynchronizeConfiguration.ID>
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if gettingremotedata == false {
                    if let estimatedtask {
                        DetailsOneTaskView(estimatedtask: estimatedtask)
                            .onDisappear(perform: {
                                estimateprogressdetails.appendrecordestimatedlist(estimatedtask)
                            })
                    }
                } else {
                    VStack {
                        // Only one task is estimated if selected, if more than one
                        // task is selected multiple estimation is selected. That is why
                        // that is why (uuid: selecteduuids.first)
                        if let config = getconfig(uuid: selecteduuids.first) {
                            Text("Estimating now: " + "\(config.backupID)")
                        }

                        ProgressView()
                    }
                }
            }
        }
        .onAppear(perform: {
            var selectedconfig: SynchronizeConfiguration?
            let selected = configurations.filter { config in
                selecteduuids.contains(config.id)
            }
            if selected.count == 1 {
                selectedconfig = selected[0]
            }
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }
            let task = ProcessRsync(arguments: arguments,
                                    config: selectedconfig,
                                    processtermination: processtermination)
            task.executeProcess()
        })
    }

    func getconfig(uuid: UUID?) -> SynchronizeConfiguration? {
        let configuration = configurations.filter { $0.id == uuid }
        guard configuration.count == 1 else { return nil }
        return configuration[0]
    }
}

extension DetailsOneTaskEstimatingView {
    func processtermination(data: [String]?, hiddenID _: Int?) {
        var selectedconfig: SynchronizeConfiguration?
        let selected = configurations.filter { config in
            selecteduuids.contains(config.id)
        }
        if selected.count == 1 {
            selectedconfig = selected[0]
        }
        estimatedtask = RemoteDataNumbers(outputfromrsync: data,
                                          config: selectedconfig)
        gettingremotedata = false
    }
}
