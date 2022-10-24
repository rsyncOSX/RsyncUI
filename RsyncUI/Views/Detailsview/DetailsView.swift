//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import Foundation
import SwiftUI

struct DetailsView: View {
    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var isPresented: Bool

    @State private var remotedata: [String] = []
    @State private var gettingremotedata: Bool = false

    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1

    var body: some View {
        VStack {
            ConfigurationSelected(selectedconfig: $selectedconfig,
                                  selecteduuids: $selecteduuids,
                                  inwork: $inwork,
                                  reload: $reload)
                .frame(height: 57)

            List(remotedata, id: \.self) { line in
                Text(line)
                    .modifier(FixedTag(750, .leading))
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear(perform: {
            selecteduuids.insert(selectedconfig?.id ?? UUID())
            gettingremotedata = true
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            let task = RsyncAsync(arguments: arguments, config: selectedconfig,
                                  processtermination: processtermination)
            Task {
                await task.executeProcess()
            }
        })
        .padding()
        .frame(minWidth: 1100, minHeight: 400)

        /*
         if gettingremotedata {
             RotatingDotsIndicatorView()
                 .frame(width: 25.0, height: 25.0)
                 .foregroundColor(.red)
         }
         */
    }
}

extension DetailsView {
    func processtermination(data: [String]?) {
        remotedata = data ?? []
        gettingremotedata = false
    }

    func dismissview() {
        isPresented = false
    }
}
