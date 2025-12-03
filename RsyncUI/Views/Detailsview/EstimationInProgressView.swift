//
//  EstimationInProgressView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 19/12/2023.
//

import SwiftUI

struct EstimationInProgressView: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        ZStack {
            if let uuid = getuuid(uuid: progressdetails.configurationtobestimated) {
                EstimateTableView(progressdetails: progressdetails,
                                  estimatinguuid: uuid,
                                  configurations: configurations)
            }

            VStack {
                Spacer()

                if configurations.count == 1 || selecteduuids.count == 1 {
                    progressviewonetaskonly
                } else {
                    progressviewestimation
                }
            }

            if focusaborttask { labelaborttask }
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .frame(maxWidth: .infinity)
    }

    var progressviewestimation: some View {
        ProgressView("",
                     value: progressdetails.numberofconfigurationsestimated,
                     total: Double(progressdetails.numberofconfigurations))
            .onAppear {
                // Either is there some selceted tasks or if not
                // the EstimateTasks selects all tasks to be estimated
                
                Estimate(profile: profile,
                                configurations: configurations,
                                selecteduuids: selecteduuids,
                                progressdetails: progressdetails,
                                filehandler:  { _ in },
                                updateconfigurations: { _ in })
            }
            .progressViewStyle(.circular)
    }

    var progressviewonetaskonly: some View {
        ProgressView()
            .onAppear {
                // Either is there some selceted tasks or if not
                // the EstimateTasks selects all tasks to be estimated
                Estimate(profile: profile,
                                configurations: configurations,
                                selecteduuids: selecteduuids,
                                progressdetails: progressdetails,
                                filehandler:  { _ in },
                                updateconfigurations: { _ in })
            }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    func getuuid(uuid: UUID?) -> SynchronizeConfiguration.ID? {
        if let index = configurations.firstIndex(where: { $0.id == uuid }) {
            return configurations[index].id
        }
        return nil
    }

    func abort() {
        InterruptProcess()
        progressdetails.resetcounts()
    }
}
