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
        ZStack {
            ProgressView("Estimating",
                         value: estimateprogressdetails.numberofconfigurationsestimated,
                         total: Double(rsyncUIdata.getallconfigurations()?.count ?? 0))

            if estimateprogressdetails.estimatealltasksasync { progressviewestimateasync }

        }.onAppear {
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
        AlertToast(displayMode: .alert, type: .loading)
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
    }
}
