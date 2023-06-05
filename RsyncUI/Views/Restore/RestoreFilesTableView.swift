//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @State private var datalist: [String] = []
    @State private var selectedid: RestoreFileRecord.ID?
    @State private var gettingfilelist: Bool = false
    @Binding var filestorestore: String
    @Binding var filterstring: String

    var config: Configuration?

    var body: some View {
        ZStack {
            Table(filelist, selection: $selectedid.onChange {
                let record = filelist.filter { $0.id == selectedid }
                guard record.count > 0 else { return }
                filestorestore = record[0].filename
            }) {
                TableColumn("Filenames", value: \.filename)
            }
            .onAppear {
                Task {
                    if let config = config {
                        guard config.task != SharedReference.shared.syncremote else { return }
                        gettingfilelist = true
                        await getfilelist(config)
                    }
                }
            }
            .onDisappear {
                if SharedReference.shared.process != nil {
                    _ = InterruptProcess()
                }
            }

            if gettingfilelist == true { ProgressView() }
        }
    }

    var filelist: [RestoreFileRecord] {
        guard datalist.count > 0 else { return [] }
        let data = TrimOne(datalist).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        return data.map { filename in
            RestoreFileRecord(filename: filename)
        }
    }

    func processtermination(data: [String]?) {
        gettingfilelist = false
        datalist = data ?? []
    }

    @MainActor
    func getfilelist(_ config: Configuration) async {
        let snapshot: Bool = (config.snapshotnum != nil) ? true : false
        let arguments = RestorefilesArguments(task: .rsyncfilelistings,
                                              config: config,
                                              remoteFile: nil,
                                              localCatalog: nil,
                                              drynrun: nil,
                                              snapshot: snapshot).getArguments()
        let command = RsyncAsync(arguments: arguments,
                                 processtermination: processtermination)
        await command.executeProcess()
    }
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String = ""
}
