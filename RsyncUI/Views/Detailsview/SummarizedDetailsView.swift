//
//  SummarizedDetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import SwiftUI

struct SummarizedDetailsView: View {
    @Bindable var progressdetails: ProgressDetails
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    /// Navigation path for executetasks
    @Binding var executetaskpath: [Tasks]

    @State private var previewScope = Set<UUID>()
    @State private var isPresentingConfirm: Bool = false

    let configurations: [SynchronizeConfiguration]
    let profile: String?
    /// URL code
    let queryitem: URLQueryItem?

    var body: some View {
        VStack {
            SummarizedDetailsContentView(progressdetails: progressdetails,
                                         selecteduuids: $selecteduuids,
                                         executetaskpath: $executetaskpath,
                                         isPresentingConfirm: $isPresentingConfirm,
                                         previewScope: previewScope,
                                         configurations: configurations,
                                         profile: profile,
                                         queryitem: queryitem)
                .onAppear {
                    guard previewScope.isEmpty else { return }
                    previewScope = Set(configurations.filter {
                        $0.task != SharedReference.shared.halted && (selecteduuids.isEmpty || selecteduuids.contains($0.id))
                    }.map(\.id))
                    guard !progressdetails.estimatealltasksinprogress else { return }
                    progressdetails.resetCounts()
                    progressdetails.startEstimation()
                }
        }
    }
}
