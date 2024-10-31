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
    
    @State private var estimatinguuid: SynchronizeConfiguration.ID?

    let profile: String?
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        VStack {
            
            if let uuid = getuuid(uuid: estimateprogressdetails.configurationtobestimated) {
                EstimateView(estimatinguuid: uuid, configurations: configurations)
            }
            
            progressviewestimation
        }
        .onAppear {
            estimateprogressdetails.resetcounts()
            executeprogressdetails.estimatedlist = nil
            estimateprogressdetails.startestimation()
        }
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
                                             estimateprogressdetails: estimateprogressdetails,
                                             uuids: selecteduuids,
                                             filter: "")
                estimate.startestimation()
            }
            .onDisappear {
                executeprogressdetails.estimatedlist = nil
                executeprogressdetails.estimatedlist = estimateprogressdetails.getestimatedlist()
                nodatatosynchronize = if let data = estimateprogressdetails.getestimatedlist()?.filter({
                    $0.datatosynchronize == true })
                {
                    data.isEmpty
                } else {
                    false
                }
            }
            .progressViewStyle(.circular)
    }
    
    func getuuid(uuid: UUID?) -> SynchronizeConfiguration.ID? {
        if let index = configurations.firstIndex(where: { $0.id == uuid }) {
            return configurations[index].id
        }
        return nil
    }
}


struct EstimateView: View {
    let estimatinguuid: SynchronizeConfiguration.ID
    let configurations: [SynchronizeConfiguration]

    var body: some View {
        Table(configurations) {
            TableColumn("") { data in
                if data.id == estimatinguuid {
                    Image(systemName: "arrowshape.right.fill")
                        .foregroundColor(Color(.blue))
                }
            }
            .width(min: 25, max: 25)
            TableColumn("Synchronize ID") { data in
                if data.backupID.isEmpty == true {
                    Text("Synchronize ID")

                } else {
                    Text(data.backupID)
                }
            }
            .width(min: 50, max: 200)
            TableColumn("Task", value: \.task)
                .width(max: 80)
            TableColumn("Local catalog", value: \.localCatalog)
                .width(min: 80, max: 300)
            TableColumn("Remote catalog", value: \.offsiteCatalog)
                .width(min: 80, max: 300)
            TableColumn("Server") { data in
                if data.offsiteServer.count > 0 {
                    Text(data.offsiteServer)
                } else {
                    Text("localhost")
                }
            }
            .width(min: 50, max: 90)
        }
    }
}
