//
//  DetailsOneTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Foundation
import SwiftUI

struct DetailsOneTask: View {
    let estimatedtask: RemoteDataNumbers

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Form {
                    VStack(alignment: .leading) {
                        HStack {
                            LabeledContent("Synchronize ID: ") {
                                if estimatedtask.backupID.count == 0 {
                                    Text("Synchronize ID")
                                        .foregroundColor(.blue)
                                } else {
                                    Text(estimatedtask.backupID)
                                        .foregroundColor(.blue)
                                }
                            }

                            LabeledContent("Task: ") {
                                Text(estimatedtask.task)
                                    .foregroundColor(.blue)
                            }
                        }

                        LabeledContent("Local catalog: ") {
                            Text(estimatedtask.localCatalog)
                                .foregroundColor(.blue)
                        }
                        LabeledContent("Remote catalog: ") {
                            Text(estimatedtask.offsiteCatalog)
                                .foregroundColor(.blue)
                        }
                        LabeledContent("Server: ") {
                            if estimatedtask.offsiteServer.count == 0 {
                                Text("localhost")
                                    .foregroundColor(.blue)
                            } else {
                                Text(estimatedtask.offsiteServer)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }

                Form {
                    HStack {
                        VStack(alignment: .trailing) {
                            LabeledContent("Total number of files: ") {
                                Text(estimatedtask.totalNumber)
                                    .foregroundColor(.blue)
                            }

                            LabeledContent("Total number of catalogs: ") {
                                Text(estimatedtask.totalDirs)
                                    .foregroundColor(.blue)
                            }

                            LabeledContent("Total numbers: ") {
                                Text(estimatedtask.totalNumber_totalDirs)
                                    .foregroundColor(.blue)
                            }

                            LabeledContent("Total bytes: ") {
                                Text(estimatedtask.totalNumberSizebytes)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("1 kB is 1000 bytes")
                            Text("1 MB is 1 000 000 bytes")
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("^[\(estimatedtask.newfiles_Int) file](inflect: true) new")

                            Text("^[\(estimatedtask.deletefiles_Int) file](inflect: true) for delete")

                            Text("^[\(estimatedtask.transferredNumber_Int) file](inflect: true) changed")

                            Text("^[\(estimatedtask.transferredNumberSizebytes_Int) byte](inflect: true) for transfer")
                        }
                        .padding()
                    }
                }
            }

            Table(outputfromrsync.output) {
                TableColumn("") { data in
                    Text(data.line)
                }
            }
        }
    }

    var outputfromrsync: ObservableOutputfromrsync {
        let data = ObservableOutputfromrsync()
        data.generateoutput(estimatedtask.outputfromrsync)
        return data
    }
}
