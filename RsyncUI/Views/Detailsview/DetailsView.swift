//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/10/2022.
//

import Foundation
import Observation
import SwiftUI

struct DetailsView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(InprogressCountEstimation.self) var inprogresscountmultipletask

    var selectedconfig: Configuration?

    @State private var gettingremotedata = true
    @State private var estimateddataonetask = Estimateddataonetask()
    @State private var outputfromrsync = Outputfromrsync()

    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                VStack(alignment: .leading) {
                    if #available(macOS 13.0, *) {
                        Form {
                            if gettingremotedata == false {
                                HStack {
                                    VStack(alignment: .leading) {
                                        LabeledContent("Synchronize ID: ") {
                                            if estimateddataonetask.estimatedlistonetask[0].backupID.count == 0 {
                                                Text("Synchronize ID")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text(estimateddataonetask.estimatedlistonetask[0].backupID)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        LabeledContent("Task: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].task)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Local catalog: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].localCatalog)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Remote catalog: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].offsiteCatalog)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Server: ") {
                                            if estimateddataonetask.estimatedlistonetask[0].offsiteServer.count == 0 {
                                                Text("localhost")
                                                    .foregroundColor(.blue)
                                            } else {
                                                Text(estimateddataonetask.estimatedlistonetask[0].offsiteServer)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        LabeledContent("New: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].newfiles)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Delete: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].deletefiles)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Files: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].transferredNumber)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Bytes: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].transferredNumberSizebytes)
                                                .foregroundColor(.blue)
                                        }
                                    }

                                    VStack(alignment: .trailing) {
                                        LabeledContent("Tot num: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].totalNumber)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Tot bytes: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].totalNumberSizebytes)
                                                .foregroundColor(.blue)
                                        }
                                        LabeledContent("Tot dir: ") {
                                            Text(estimateddataonetask.estimatedlistonetask[0].totalDirs)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        Table(estimateddataonetask.estimatedlistonetask) {
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

                        Table(estimateddataonetask.estimatedlistonetask) {
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

                    Table(outputfromrsync.output) {
                        TableColumn("Output") { data in
                            Text(data.line)
                        }
                        .width(min: 800)
                    }
                }

                if gettingremotedata { AlertToast(displayMode: .alert, type: .loading) }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Dismiss") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear(perform: {
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            guard arguments != nil else { return }
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
        outputfromrsync.generatedata(data)
        estimateddataonetask.update(data: data, hiddenID: selectedconfig?.hiddenID, config: selectedconfig)
        gettingremotedata = false
        // Adding computed estimate if later execute and view of progress
        if estimateddataonetask.estimatedlistonetask.count == 1 {
            inprogresscountmultipletask.resetcounts()
            inprogresscountmultipletask.appenduuid(selectedconfig?.id ?? UUID())
            inprogresscountmultipletask.appendrecordestimatedlist(estimateddataonetask.estimatedlistonetask[0])
        }
    }
}

@Observable
final class Estimateddataonetask {
    var estimatedlistonetask = [RemoteinfonumbersOnetask]()

    func update(data: [String]?, hiddenID: Int?, config: Configuration?) {
        let record = RemoteinfonumbersOnetask(hiddenID: hiddenID,
                                              outputfromrsync: data,
                                              config: config)
        estimatedlistonetask = [RemoteinfonumbersOnetask]()
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
            if number > 10000 { throw OutputIsTruncated.istruncated }
        } catch let e {
            let error = e
            alerterror(error: error)
            return true
        }
        return false
    }

    func generatedata(_ data: [String]?) {
        var count = data?.count
        let summarycount = data?.count
        if count ?? 0 > 10000 { count = 10000 }
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
    func alerterror(error: Error) {
        SharedReference.shared.errorobject?.alerterror(error: error)
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
