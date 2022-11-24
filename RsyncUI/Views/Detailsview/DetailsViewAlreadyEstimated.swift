//
//  DetailsViewAlreadyEstimted.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/11/2022.
//

import Foundation
import SwiftUI

struct DetailsViewAlreadyEstimated: View {
    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var isPresented: Bool
    var estimatedlist: [RemoteinfonumbersOnetask]

    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1

    var body: some View {
        VStack {
            ZStack {
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
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1100, minHeight: 500)
        .onAppear {
            selecteduuids.insert(selectedconfig?.id ?? UUID())
        }
    }

    var remotedata: [String] {
        let output: [RemoteinfonumbersOnetask] = estimatedlist.filter { $0.hiddenID == selectedconfig?.hiddenID }
        guard output.count > 0 else { return [] }
        return output[0].outputfromrsync ?? []
    }
}

extension DetailsViewAlreadyEstimated {
    func dismissview() {
        isPresented = false
    }
}
