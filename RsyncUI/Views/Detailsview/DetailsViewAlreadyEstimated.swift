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
                    Table(data) {
                        TableColumn("Synchronize ID", value: \.backupID)
                            .width(min: 50, max: 200)
                        TableColumn("Task", value: \.task)
                            .width(max: 80)
                        TableColumn("Local catalog", value: \.localCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Remote catalog", value: \.offsiteCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Server", value: \.offsiteServer)
                            .width(max: 70)
                        TableColumn("User", value: \.offsiteUsername)
                            .width(max: 70)
                    }
                    .frame(maxHeight: 50)
                    .foregroundColor(.blue)

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
        .frame(minWidth: 900, minHeight: 500)
        .onAppear {
            selecteduuids.insert(selectedconfig?.id ?? UUID())
        }
    }

    var data: [Configuration] {
        if let test = selectedconfig {
            return [test]
        } else {
            return []
        }
    }

    var remotedata: [String] {
        let output: [RemoteinfonumbersOnetask] = estimatedlist.filter { $0.id == selectedconfig?.id }
        guard output.count > 0 else { return [] }
        return output[0].outputfromrsync ?? []
    }
}

extension DetailsViewAlreadyEstimated {
    func dismissview() {
        isPresented = false
    }
}
