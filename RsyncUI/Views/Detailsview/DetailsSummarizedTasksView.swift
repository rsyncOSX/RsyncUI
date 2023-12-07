//
//  DetailsSummarizedTasksView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct DetailsSummarizedTasksView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata

    @Binding var selecteduuids: Set<UUID>
    @Binding var execute: Bool

    var estimatedlist: [RemoteDataNumbers]
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var timervalue: Double = 0
    @State private var timerbuttonvalue: Int = SharedReference.shared.automaticexecutetime
    @State private var canceltimer: Bool = false

    var body: some View {
        VStack {
            headingtitle

            HStack {
                Table(estimatedlist) {
                    TableColumn("Synchronize ID") { data in
                        if data.datatosynchronize {
                            Text(data.backupID)
                                .foregroundColor(.blue)
                        } else {
                            Text(data.backupID)
                        }
                    }
                    .width(min: 80, max: 200)
                    TableColumn("Task", value: \.task)
                        .width(max: 80)
                    TableColumn("Local catalog", value: \.localCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Remote catalog", value: \.offsiteCatalog)
                        .width(min: 100, max: 300)
                    TableColumn("Server") { data in
                        if data.offsiteServer.count > 0 {
                            Text(data.offsiteServer)
                        } else {
                            Text("localhost")
                        }
                    }
                    .width(max: 80)
                }

                Table(estimatedlist) {
                    TableColumn("New") { files in
                        if files.datatosynchronize {
                            Text(files.newfiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.newfiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Delete") { files in
                        if files.datatosynchronize {
                            Text(files.deletefiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.deletefiles)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Files") { files in
                        if files.datatosynchronize {
                            Text(files.transferredNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.transferredNumber)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .width(max: 40)
                    TableColumn("Bytes") { files in
                        if files.datatosynchronize {
                            Text(files.transferredNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .foregroundColor(.blue)
                        } else {
                            Text(files.transferredNumberSizebytes)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
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
            }
            Spacer()

            HStack {
                Spacer()

                if datatosynchronize == false {
                    Text("There seems to be no data to synchronize")
                        .font(.title2)
                }

                Spacer()

                if canceltimer == false,
                   SharedReference.shared.automaticexecute,
                   datatosynchronize == true
                {
                    Button(String(timerbuttonvalue - Int(timervalue))) {
                        timer.upstream.connect().cancel()
                        canceltimer = true
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }

                if datatosynchronize == true {
                    Button("Synchronize") {
                        execute = true
                        dismiss()
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }

                Button("Dismiss") { dismiss() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 1250, minHeight: 400)
        .onReceive(timer) { _ in
            guard datatosynchronize == true else { return }
            guard SharedReference.shared.automaticexecute == true else { return }
            timervalue += 1
            if timervalue > Double(SharedReference.shared.automaticexecutetime - 1) {
                timer.upstream.connect().cancel()
                execute = true
                dismiss()
            }
        }
        .onDisappear {
            timer.upstream.connect().cancel()
        }
    }

    var headingtitle: some View {
        Text("Estimated tasks")
            .font(.title2)
            .padding()
    }

    var datatosynchronize: Bool {
        return !estimatedlist.filter { $0.datatosynchronize == true }.isEmpty
    }
}
