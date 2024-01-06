//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import SwiftUI

struct EstimationInProgressView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails

    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var nodatatosynchronize: Bool

    var body: some View {
        VStack {
            if let config = rsyncUIdata.getconfig(uuid: estimateprogressdetails.configurationtobestimated) {
                Text("Estimating now: " + "\(config.backupID)")
            }

            progressviewestimateasync
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            executeprogressdetails.resetcounts()
            estimateprogressdetails.startestimateasync()
        }
        .padding()
    }

    var progressviewestimateasync: some View {
        ProgressView("",
                     value: estimateprogressdetails.numberofconfigurationsestimated,
                     total: Double(rsyncUIdata.getallconfigurations()?.count ?? 0))
            .onAppear {
                Task {
                    // Either is there some selcetd tasks or if not
                    // the EstimateTasksAsync selects all tasks to be
                    // estimated.
                    let estimate = EstimateTasksAsync(profile: rsyncUIdata.profile,
                                                      configurations: rsyncUIdata,
                                                      estimateprogressdetails: estimateprogressdetails,
                                                      uuids: selecteduuids,
                                                      filter: "")
                    await estimate.startestimation()
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
    }
}
