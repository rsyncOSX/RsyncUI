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

            progressviewestimation
            
            if focusaborttask { labelaborttask }
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            executeprogressdetails.estimatedlist = nil
            estimateprogressdetails.startestimation()
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .padding()
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
            .onDisappear {
                // executeprogressdetails.estimatedlist = nil
                // executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
                nodatatosynchronize = if let data = estimateprogressdetails.estimatedlist?.filter({
                    $0.datatosynchronize == true })
                {
                    data.isEmpty
                } else {
                    false
                }
            }
            .progressViewStyle(.circular)
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
        executeprogressdetails.estimatedlist = nil
    }
}
