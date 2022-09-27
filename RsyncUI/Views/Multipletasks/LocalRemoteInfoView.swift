//
//  LocalRemoteInfoView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2022.
//

import SwiftUI

struct LocalRemoteInfoView: View {
    @Binding var dismiss: Bool
    @Binding var localdata: [String]
    @Binding var selectedconfig: Configuration?

    @State private var remotedata: [String] = []
    @State private var gettingremotedata: Bool = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Section("Local") {
                    local
                }

                Spacer()

                Section("Remote") {
                    remote
                }
            }
            if gettingremotedata {
                ProgressView()
            }
        }
        .padding()
        // .frame(width: 800, height: 400)

        Spacer()

        HStack {
            Spacer()

            Button("Remote") {
                gettingremotedata = true
                let arguments = ArgumentsSynchronize(config: selectedconfig)
                    .argumentssynchronize(dryRun: true, forDisplay: false)
                let task = RsyncAsync(arguments: arguments, config: selectedconfig,
                                      processtermination: processtermination)
                Task {
                    await task.executeProcess()
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Dismiss") { dismiss = false }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }

    var local: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Last run" + ": ")
                Text(selectedconfig?.dateRun ?? "")
            }
            HStack {
                Text("Number of files" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumber ?? "")
            }
            HStack {
                Text("Number of catalogs" + ": ")
                Text(remoteinfonumberslocalcatalog.totalDirs ?? "")
            }
            HStack {
                Text("Total size (kB)" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumberSizebytes ?? "")
            }
        }
    }

    var remote: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("New files" + ": ")
                Text(remoteinfonumbersremotecatalog.newfiles ?? "")
            }
            HStack {
                Text("Delete files" + ": ")
                Text(remoteinfonumbersremotecatalog.deletefiles ?? "")
            }
            HStack {
                Text("KB to be transferred" + ": ")
                Text(remoteinfonumbersremotecatalog.transferredNumberSizebytes ?? "")
            }
            HStack {
                Text("Number of files" + ": ")
                Text(remoteinfonumbersremotecatalog.totalNumber ?? "")
            }
            HStack {
                Text("Number of catalogs" + ": ")
                Text(remoteinfonumbersremotecatalog.totalDirs ?? "")
            }
            HStack {
                Text("Total size (kB)" + ": ")
                Text(remoteinfonumbersremotecatalog.totalNumberSizebytes ?? "")
            }
        }
    }

    var remoteinfonumberslocalcatalog: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: localdata)
    }

    var remoteinfonumbersremotecatalog: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: remotedata)
    }
}

extension LocalRemoteInfoView {
    func processtermination(data: [String]?) {
        remotedata = data ?? []
        gettingremotedata = false
    }
}
