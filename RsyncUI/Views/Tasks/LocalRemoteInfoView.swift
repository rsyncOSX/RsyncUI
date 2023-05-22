//
//  LocalRemoteInfoView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/09/2022.
//
// swiftlint:disable line_length

import SwiftUI

struct LocalRemoteInfoView: View {
    @SwiftUI.Environment(\.dismiss) var dismiss
    @Binding var localdata: [String]
    var selectedconfig: Configuration?

    @State private var remotedata: [String] = []
    @State private var gettingremotedata: Bool = false

    var body: some View {
        HStack(alignment: .bottom) {
            local
            remote
        }
        .padding()
        .onAppear(perform: {
            gettingremotedata = true
            let arguments = ArgumentsSynchronize(config: selectedconfig)
                .argumentssynchronize(dryRun: true, forDisplay: false)
            let task = RsyncAsync(arguments: arguments,
                                  processtermination: processtermination)
            Task {
                await task.executeProcess()
            }
        })

        Spacer()

        HStack {
            Spacer()

            if gettingremotedata { ProgressView() }

            Spacer()

            Button("Dismiss") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .frame(minWidth: 440, minHeight: 75)
    }

    var local: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Local data")
                    .font(.title)
                    .frame(alignment: .leading)
            }
            HStack {
                Text("Last run" + ": ")
                Text(selectedconfig?.dateRun ?? "")
            }
            HStack {
                Text("Number of files" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumber)
            }
            HStack {
                Text("Number of catalogs" + ": ")
                Text(remoteinfonumberslocalcatalog.totalDirs)
            }
            HStack {
                Text("Total size (kB)" + ": ")
                Text(remoteinfonumberslocalcatalog.totalNumberSizebytes)
            }
        }
    }

    var remote: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Remote data")
                    .font(.title)
                    .frame(alignment: .leading)
            }
            HStack {
                Text("New files" + ": ")
                Text(remoteinfonumbersremotecatalog.newfiles)
            }
            HStack {
                Text("Delete files" + ": ")
                Text(remoteinfonumbersremotecatalog.deletefiles)
            }
            HStack {
                Text("KB to be transferred" + ": ")
                Text(remoteinfonumbersremotecatalog.transferredNumberSizebytes)
            }
            HStack {
                Text("Number of files" + ": ")
                Text(remoteinfonumbersremotecatalog.totalNumber)
            }
            HStack {
                Text("Number of catalogs" + ": ")
                Text(remoteinfonumbersremotecatalog.totalDirs)
            }
            HStack {
                Text("Total size (kB)" + ": ")
                Text(remoteinfonumbersremotecatalog.totalNumberSizebytes)
            }
        }
    }

    var remoteinfonumberslocalcatalog: RemoteinfonumbersOnetask {
        // return RemoteinfoNumbers(data: localdata)
        return RemoteinfonumbersOnetask(hiddenID: selectedconfig?.hiddenID, outputfromrsync: localdata, config: selectedconfig)
    }

    var remoteinfonumbersremotecatalog: RemoteinfonumbersOnetask {
        return RemoteinfonumbersOnetask(hiddenID: selectedconfig?.hiddenID, outputfromrsync: remotedata, config: selectedconfig)
    }
}

extension LocalRemoteInfoView {
    func processtermination(data: [String]?) {
        remotedata = data ?? []
        gettingremotedata = false
    }
}
