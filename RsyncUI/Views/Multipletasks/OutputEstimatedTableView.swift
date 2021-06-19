//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputEstimatedTableView: View {
    @Binding var isPresented: Bool
    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        VStack {
            headingtitle

            HStack {
                table1

                table2
            }

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(minWidth: 1000, minHeight: 400)
        .padding()
    }

    var table1: some View {
        Table {
            TableColumn("Task", value: \.task)
            TableColumn("ID", value: \.backupID)
            TableColumn("Local", value: \.localCatalog)
            TableColumn("Remote", value: \.offsiteCatalog)
            TableColumn("Server", value: \.offsiteServer)
            TableColumn("Date run", value: \.dateRun)
        } rows: {
            ForEach(estimatedlist) { estimates in
                TableRow(estimates)
            }
        }
    }

    var table2: some View {
        Table {
            TableColumn("ID", value: \.backupID)
            TableColumn("New", value: \.newfiles)
            TableColumn("Deleted", value: \.deletefiles)
            TableColumn("Files", value: \.transferredNumber)
            TableColumn("Bytes", value: \.transferredNumberSizebytes)
            TableColumn("Total number", value: \.totalNumber)
            TableColumn("Total size", value: \.totalNumberSizebytes)
            TableColumn("Total dir", value: \.totalDirs)
        } rows: {
            ForEach(estimatedlist) { estimates in
                TableRow(estimates)
            }
        }
    }

    var headingtitle: some View {
        Text(NSLocalizedString("Estimated tasks", comment: "RsyncCommandView"))
            .font(.title2)
            .padding()
    }
}

extension OutputEstimatedTableView {
    func sometablefunc() {}

    func dismissview() {
        isPresented = false
    }
}
