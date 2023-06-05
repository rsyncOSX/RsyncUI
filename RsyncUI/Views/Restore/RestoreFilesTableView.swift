//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @State private var filelist: [RestoreFileRecord] = []
    @State private var selectedid: RestoreFileRecord.ID?
    // @State private var filterstring: String = ""
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
            .searchable(text: $filterstring)

            if gettingfilelist == true { ProgressView() }
        }
    }

    func processtermination(data: [String]?) {
        gettingfilelist = false
        guard data?.count ?? 0 > 0 else { return }
        let data = TrimOne(data ?? []).trimmeddata.filter { filterstring.isEmpty ? true : $0.contains(filterstring) }
        filelist = data.map { filename in
            RestoreFileRecord(filename: filename)
        }
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
