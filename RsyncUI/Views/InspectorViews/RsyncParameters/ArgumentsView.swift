//
//  ArgumentsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 16/09/2024.
//

import SwiftUI

struct ArgumentsView: View {
    @State private var otherselectedrsynccommand = OtherRsyncCommand.listRemoteFiles
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()

    let config: SynchronizeConfiguration

    var body: some View {
        OtherRsyncCommandsView(otherselectedrsynccommand: $otherselectedrsynccommand, config: config)

            .padding()
    }
}
