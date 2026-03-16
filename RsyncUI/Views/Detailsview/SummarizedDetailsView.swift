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

    @State private var focusstartexecution: Bool = false
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
                                         configurations: configurations,
                                         profile: profile,
                                         queryitem: queryitem)
                .focusedSceneValue(\.startexecution, $focusstartexecution)
                .onAppear {
                    guard progressdetails.estimatealltasksinprogress == false else {
                        return
                    }
                    progressdetails.resetCounts()
                    progressdetails.startEstimation()
                }
        }

        Spacer()

        if focusstartexecution { labelstartexecution }
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundStyle(.black)
            .onAppear {
                executetaskpath.removeAll()
                executetaskpath.append(Tasks(task: .executestimatedview))
                focusstartexecution = false
            }
    }
}
