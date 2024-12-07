//
//  ArgumentsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import SwiftUI

struct ArgumentsVerifyView: View {
    @Binding var selectedconfig: SynchronizeConfiguration?

    @State private var otherselectedrsynccommand = OtherRsyncCommand.push_local
    @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var configurations = [SynchronizeConfiguration]()
    
    let profile: String?

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids,
                                 profile: profile,
                                 configurations: configurations)
                .frame(maxWidth: .infinity)
                
            Spacer()

            OtherRsyncCommandsView(config: $selectedconfig, otherselectedrsynccommand: $otherselectedrsynccommand)
                .disabled(selectedconfig == nil)
        }
        .onAppear(perform: {
            if let selectedconfig {
                configurations.append(selectedconfig)
            }
        })
        .padding()
    }
}
