//
//  NavigationDetailsOneTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Foundation
import SwiftUI

@available(macOS 14.0, *)
struct NavigationDetailsOneTask: View {
    let estimatedlist: [RemoteinfonumbersOnetask]
    @Binding var selecteduuids: Set<Configuration.ID>

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Form {
                    VStack(alignment: .leading) {
                        LabeledContent("Synchronize ID: ") {
                            if estimatedlistonetask[0].backupID.count == 0 {
                                Text("Synchronize ID")
                                    .foregroundColor(.blue)
                            } else {
                                Text(estimatedlistonetask[0].backupID)
                                    .foregroundColor(.blue)
                            }
                        }
                        LabeledContent("Task: ") {
                            Text(estimatedlistonetask[0].task)
                                .foregroundColor(.blue)
                        }
                        LabeledContent("Local catalog: ") {
                            Text(estimatedlistonetask[0].localCatalog)
                                .foregroundColor(.blue)
                        }
                        LabeledContent("Remote catalog: ") {
                            Text(estimatedlistonetask[0].offsiteCatalog)
                                .foregroundColor(.blue)
                        }
                        LabeledContent("Server: ") {
                            if estimatedlistonetask[0].offsiteServer.count == 0 {
                                Text("localhost")
                                    .foregroundColor(.blue)
                            } else {
                                Text(estimatedlistonetask[0].offsiteServer)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }

                Form {
                    HStack {
                        VStack(alignment: .trailing) {
                            LabeledContent("New: ") {
                                Text(estimatedlistonetask[0].newfiles)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Delete: ") {
                                Text(estimatedlistonetask[0].deletefiles)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Files: ") {
                                Text(estimatedlistonetask[0].transferredNumber)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Bytes: ") {
                                Text(estimatedlistonetask[0].transferredNumberSizebytes)
                                    .foregroundColor(.blue)
                            }
                        }

                        VStack(alignment: .trailing) {
                            LabeledContent("Tot num: ") {
                                Text(estimatedlistonetask[0].totalNumber)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Tot bytes: ") {
                                Text(estimatedlistonetask[0].totalNumberSizebytes)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Tot dir: ") {
                                Text(estimatedlistonetask[0].totalDirs)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }
            }

            Table(outputfromrsync.output) {
                TableColumn("") { data in
                    Text(data.line)
                }
            }
        }
        .onDisappear(perform: {
            selecteduuids.removeAll()
        })
    }

    var estimatedlistonetask: [RemoteinfonumbersOnetask] {
        return estimatedlist.filter { $0.id == selecteduuid }
    }

    var selecteduuid: Configuration.ID? {
        return selecteduuids.first
    }

    var outputfromrsync: Outputfromrsync {
        let output: [RemoteinfonumbersOnetask] = estimatedlist.filter { $0.id == selecteduuid }
        if output.count > 0 {
            let data = Outputfromrsync()
            data.generatedata(output[0].outputfromrsync)
            return data
        }
        return Outputfromrsync()
    }
}
