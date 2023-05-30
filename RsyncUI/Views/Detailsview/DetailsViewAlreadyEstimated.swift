//
//  DetailsViewAlreadyEstimted.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/11/2022.
//

import Foundation
import SwiftUI

struct DetailsViewAlreadyEstimated: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    var estimatedlist: [RemoteinfonumbersOnetask]
    var selectedconfig: Configuration?

    @StateObject var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack(alignment: .leading) {
            Text("Details")
                .font(.title2)
                .padding()

            VStack(alignment: .leading) {
                if #available(macOS 13.0, *) {
                    Form {
                        HStack {
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

                            Spacer()

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
                    }

                } else {
                    Table(estimatedlistonetask) {
                        TableColumn("Synchronize ID") { data in
                            if data.backupID.count == 0 {
                                Text("Synchronize ID")
                            } else {
                                Text(data.backupID)
                            }
                        }
                        .width(min: 100, max: 200)
                        TableColumn("Task", value: \.task)
                            .width(max: 80)
                        TableColumn("Local catalog", value: \.localCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Remote catalog", value: \.offsiteCatalog)
                            .width(min: 80, max: 300)
                        TableColumn("Server") { data in
                            if data.offsiteServer.count == 0 {
                                Text("localhost")
                            } else {
                                Text(data.offsiteServer)
                            }
                        }
                        .width(max: 70)
                    }
                    .frame(width: 650, height: 50, alignment: .center)
                    .foregroundColor(.blue)

                    Table(estimatedlistonetask) {
                        TableColumn("New") { files in
                            Text(files.newfiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 40)
                        TableColumn("Delete") { files in
                            Text(files.deletefiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 40)
                        TableColumn("Files") { files in
                            Text(files.transferredNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 40)
                        TableColumn("Bytes") { files in
                            Text(files.transferredNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 60)
                        TableColumn("Tot num") { files in
                            Text(files.totalNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 80)
                        TableColumn("Tot bytes") { files in
                            Text(files.totalNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 80)
                        TableColumn("Tot dir") { files in
                            Text(files.totalDirs)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .width(max: 70)
                    }
                    .foregroundColor(.blue)
                    .frame(width: 450, height: 50, alignment: .center)
                }
            }

            Table(outputfromrsync.output) {
                TableColumn("Output") { data in
                    Text(data.line)
                }
                .width(min: 800)
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 900, minHeight: 500)
        .onAppear {
            let output: [RemoteinfonumbersOnetask] = estimatedlist.filter { $0.id == selectedconfig?.id }
            if output.count > 0 {
                outputfromrsync.generatedata(output[0].outputfromrsync)
            }
        }
    }

    var estimatedlistonetask: [RemoteinfonumbersOnetask] {
        return estimatedlist.filter { $0.id == selectedconfig?.id }
    }
}
