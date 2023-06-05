//
//  RestoreFilesTableView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 05/06/2023.
//

import SwiftUI

struct RestoreFilesTableView: View {
    @StateObject var restorefilelist = ObserveableRestoreTableFilelist()
    @State private var selectedfileid = Set<RestoreFileRecord.ID>()

    // @State private var selection: String?
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var config: Configuration?

    var body: some View {
        VStack {
            Table(filelist, selection: $selectedfileid) {
                TableColumn("Filenames") { data in
                    Text(data.filename)
                }
            }

            Spacer()

            if restorefilelist.gettingfilelist == true { ProgressView() }

            if focusaborttask { labelaborttask }
        }
        .padding()
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .onAppear {
            Task {
                if let config = config {
                    await restorefilelist.validatetaskandgetfilelist(config)
                }
            }
        }
        .onDisappear {
            if SharedReference.shared.process != nil {
                _ = InterruptProcess()
            }
        }
        .searchable(text: $restorefilelist.filterstring)
    }

    var filelist: [RestoreFileRecord] {
        return restorefilelist.getoutputtable() ?? []
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    func abort() {
        _ = InterruptProcess()
    }
}

struct RestoreFileRecord: Identifiable {
    let id = UUID()
    var filename: String = ""
}
