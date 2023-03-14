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

    @State private var gettingremotedata = true
    @State private var outputfromrsync: [String] = []

    // For selecting tasks, the selected index is transformed to the uuid of the task
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1

    // var data: [Configuration]
    @StateObject var estimateddataonetask = Estimateddataonetask()

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Table(estimateddataonetask.estimatedlistonetask) {
                        TableColumn("Synchronize ID", value: \.backupID)
                            .width(min: 100, max: 200)
                        TableColumn("Task", value: \.task)
                            .width(max: 80)
                        TableColumn("Local catalog", value: \.localCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Remote catalog", value: \.offsiteCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Server", value: \.offsiteServer)
                            .width(max: 70)
                        TableColumn("User", value: \.offsiteUsername)
                            .width(max: 50)
                    }
                    .frame(width: 650, height: 50, alignment: .center)
                    .foregroundColor(.blue)

                    List(outputfromrsync, id: \.self) { line in
                        Text(line)
                            .modifier(FixedTag(750, .leading))
                    }
                }

                if gettingremotedata {
                    ProgressView()
                        .frame(width: 50.0, height: 50.0)
                }
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
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            let task = RsyncAsync(arguments: arguments,
                                  processtermination: processtermination)
            Task {
                await task.executeProcess()
            }
        })
        .padding()
        .frame(minWidth: 900, minHeight: 500)
    }
}

extension DetailsView {
    func processtermination(data: [String]?) {
        outputfromrsync = data ?? []
        gettingremotedata = false
        estimateddataonetask.update(data: data, hiddenID: selectedconfig?.hiddenID, config: selectedconfig)
    }

    func dismissview() {
        isPresented = false
    }
}

final class Estimateddataonetask: ObservableObject {
    @Published var estimatedlistonetask = [RemoteinfonumbersOnetask]()

    func update(data: [String]?, hiddenID: Int?, config: Configuration?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: data,
                                              config: config)
        estimatedlistonetask = [RemoteinfonumbersOnetask]()
        estimatedlistonetask.append(record)
    }
}
