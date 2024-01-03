//
//  DetailsOneTask.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Foundation
import SwiftUI

struct DetailsOneTask: View {
    @Binding var selecteduuids: Set<Configuration.ID>

    let estimatedtask: RemoteDataNumbers

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Form {
                    VStack(alignment: .leading) {
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
                            LabeledContent("New files: ") {
                                Text(estimatedtask.newfiles)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Delete files: ") {
                                Text(estimatedtask.deletefiles)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Changed files: ") {
                                Text(estimatedtask.transferredNumber)
                                    .foregroundColor(.blue)
                            }
                            LabeledContent("Bytes: ") {
                                Text(estimatedtask.transferredNumberSizebytes)
                                    .foregroundColor(.blue)
                            }
                        }

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

    /*
     var estimatedlistonetask: RemoteDataNumbers {
         let estimate = estimatedlist.filter { $0.id == selecteduuid }
         if estimate.count == 1 {
             return estimate[0]
         } else {
             return RemoteDataNumbers()
         }
     }
     */
    var selecteduuid: Configuration.ID? {
        return selecteduuids.first
    }

    var outputfromrsync: Outputfromrsync {
        let data = Outputfromrsync()
        data.generatedata(estimatedtask.outputfromrsync)
        return data
    }
}

@Observable
final class Estimateddataonetask {
    var estimatedlistonetask = [RemoteDataNumbers]()

    func update(data: [String]?, hiddenID: Int?, config: Configuration?) {
        let record = RemoteDataNumbers(hiddenID: hiddenID,
                                       outputfromrsync: data,
                                       config: config)
        estimatedlistonetask = [RemoteDataNumbers]()
        estimatedlistonetask.append(record)
    }
}

@Observable
final class Outputfromrsync {
    var output = [Data]()

    struct Data: Identifiable {
        let id = UUID()
        var line: String
    }

    func outputistruncated(_ number: Int) -> Bool {
        do {
            if number > 20000 { throw OutputIsTruncated.istruncated }
        } catch let e {
            let error = e
            propogateerror(error: error)
            return true
        }
        return false
    }

    func generatedata(_ data: [String]?) {
        var count = data?.count
        let summarycount = data?.count
        if count ?? 0 > 20000 { count = 20000 }
        // Show the 10,000 first lines
        for i in 0 ..< (count ?? 0) {
            if let line = data?[i] {
                output.append(Data(line: line))
            }
        }
        if outputistruncated(summarycount ?? 0) {
            output.append(Data(line: ""))
            output.append(Data(line: "**** Summary *****"))
            for i in ((summarycount ?? 0) - 20) ..< (summarycount ?? 0) - 1 {
                if let line = data?[i] {
                    output.append(Data(line: line))
                }
            }
        }
    }
}

extension Outputfromrsync {
    func propogateerror(error: Error) {
        SharedReference.shared.errorobject?.alert(error: error)
    }
}

enum OutputIsTruncated: LocalizedError {
    case istruncated

    var errorDescription: String? {
        switch self {
        case .istruncated:
            return "Output from rsync was truncated"
        }
    }
}

// swiftlint: enable line_length
