//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import OSLog
import SwiftUI

struct EstimationInProgressView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails

    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var nodatatosynchronize: Bool

    var body: some View {
        VStack {
            if estimateprogressdetails.estimatealltasksasync { progressviewestimateasync }
            details
        }
        .onAppear {
            guard estimateprogressdetails.estimatealltasksasync == false else {
                Logger.process.warning("TasksView: estimate already in progress")
                return
            }
            estimateprogressdetails.resetcounts()
            executeprogressdetails.resetcounts()
            estimateprogressdetails.startestimateasync()
        }
        .padding()
    }

    var progressviewestimateasync: some View {
        ProgressView("Estimating",
                     value: estimateprogressdetails.numberofconfigurationsestimated,
                     total: Double(rsyncUIdata.getallconfigurations()?.count ?? 0))
            .onAppear {
                Task {
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      estimateprogressdetails: estimateprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: "")
                    await estimate.startexecution()
                }
            }
            .onDisappear {
                executeprogressdetails.resetcounts()
                executeprogressdetails.setestimatedlist(estimateprogressdetails.getestimatedlist())
                nodatatosynchronize = {
                    if let data = estimateprogressdetails.getestimatedlist()?.filter({
                        $0.datatosynchronize == true })
                    {
                        return data.isEmpty
                    } else {
                        return false
                    }
                }()
            }
            .progressViewStyle(.circular)
            .padding()
    }

    var details: some View {
        if let config = rsyncUIdata.getconfig(uuid: estimateprogressdetails.configurationtobestimated) {
            Text("Estimating now: " + "\(config.backupID)")
        } else {
            Text("")
        }
    }
}
