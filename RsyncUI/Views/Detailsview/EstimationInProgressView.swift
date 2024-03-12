//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import SwiftUI

struct EstimationInProgressView: View {
    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var nodatatosynchronize: Bool

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack {
            if let config = getconfig(uuid: estimateprogressdetails.configurationtobestimated) {
                VStack {
                    Text("Estimating now")
                    Text("\(config.backupID)")
                }
            }

            progressviewestimateasync
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            executeprogressdetails.estimatedlist = nil
            estimateprogressdetails.startestimateasync()
        }
        .padding()
    }

    var progressviewestimateasync: some View {
        ProgressView("",
                     value: estimateprogressdetails.numberofconfigurationsestimated,
                     total: Double(configurations.count))
            .onAppear {
                // Either is there some selceted tasks or if not
                // the EstimateTasks selects all tasks to be estimated
                let estimate = EstimateTasks(profile: profile,
                                             configurations: configurations,
                                             estimateprogressdetails: estimateprogressdetails,
                                             uuids: selecteduuids,
                                             filter: "")
                estimate.startestimation()
            }
            .onDisappear {
                executeprogressdetails.estimatedlist = nil
                executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
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

    func getconfig(uuid: UUID?) -> SynchronizeConfiguration? {
        let configuration = configurations.filter { $0.id == uuid }
        guard configuration.count == 1 else { return nil }
        return configuration[0]
    }
}
