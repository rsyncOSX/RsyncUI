//
//  ArgumentsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/12/2024.
//

import SwiftUI

struct ArgumentsVerifyView: View {
    @Binding var selectedconfig: SynchronizeConfiguration?

    @State private var pushpullcommand = PushPullCommand.push_local
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

            PushPullCommandView(config: $selectedconfig, pushpullcommand: $pushpullcommand)
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
