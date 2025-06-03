//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import SwiftUI

struct EstimationInProgressView: View {
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack {
            if let uuid = getuuid(uuid: estimateprogressdetails.configurationtobestimated) {
                EstimateTableView(estimateprogressdetails: estimateprogressdetails,
                                  estimatinguuid: uuid,
                                  configurations: configurations)
            }

            if configurations.count == 1 || selecteduuids.count == 1 {
                progressviewonetaskonly
            } else {
                progressviewestimation
            }

            if focusaborttask { labelaborttask }
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            estimateprogressdetails.startestimation()
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .frame(maxWidth: .infinity)
    }

    var progressviewestimation: some View {
        ProgressView("",
                     value: estimateprogressdetails.numberofconfigurationsestimated,
                     total: Double(configurations.count))
            .onAppear {
                // Either is there some selceted tasks or if not
                // the EstimateTasks selects all tasks to be estimated
                let estimate = EstimateTasks(profile: profile,
                                             configurations: configurations,
                                             selecteduuids: selecteduuids,
                                             estimateprogressdetails: estimateprogressdetails,
                                             filter: "")
                estimate.startestimation()
            }
            .progressViewStyle(.circular)
    }

    var progressviewonetaskonly: some View {
        ProgressView()
            .onAppear {
                // Either is there some selceted tasks or if not
                // the EstimateTasks selects all tasks to be estimated
                let estimate = EstimateTasks(profile: profile,
                                             configurations: configurations,
                                             selecteduuids: selecteduuids,
                                             estimateprogressdetails: estimateprogressdetails,
                                             filter: "")
                estimate.startestimation()
            }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    func getuuid(uuid: UUID?) -> SynchronizeConfiguration.ID? {
        if let index = configurations.firstIndex(where: { $0.id == uuid }) {
            return configurations[index].id
        }
        return nil
    }

    func abort() {
        InterruptProcess()
        estimateprogressdetails.resetcounts()
    }
}
