//
//  DetailsOneTaskRootView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 11/11/2023.
//

import Foundation
import Observation
import SwiftUI

struct DetailsOneTaskRootView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @State private var gettingremotedata = true
    @State private var estimatedtask: RemoteDataNumbers?
    @State private var outputfromrsync = Outputfromrsync()

    let selecteduuids: Set<Configuration.ID>

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                if gettingremotedata == false {
                    if let estimatedtask = estimatedtask {
                        DetailsOneTask(estimatedtask: estimatedtask)
                    }
                } else {
                    VStack {
                        ProgressView()
                            .padding()
                        details
                    }
                }
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

    var details: some View {
        if let config = rsyncUIdata.getconfig(uuid: selecteduuids.first) {
            Text("Estimating now: " + "\(config.backupID)")
        } else {
            Text("")
        }
    }
}

extension DetailsOneTaskRootView {
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
        estimatedtask = RemoteDataNumbers(hiddenID: selectedconfig?.hiddenID,
                                          outputfromrsync: data,
                                          config: selectedconfig)
        gettingremotedata = false
    }
}
