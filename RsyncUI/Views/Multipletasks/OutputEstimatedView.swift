//
//  EstimatedView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 19/01/2021.
//

import SwiftUI

struct OutputTable: View {
    @Binding var isPresented: Bool
    var estimatedlist: [RemoteinfonumbersOnetask]

    var body: some View {
        VStack {
            headingtitle

            table

            Spacer()

            HStack {
                Spacer()

                Button(NSLocalizedString("Dismiss", comment: "Dismiss button")) { dismissview() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .frame(minWidth: 1100, minHeight: 400)
        .padding()
    }

    var table: some View {
        Table {
            TableColumn("Task", value: \.task)
            TableColumn("ID", value: \.backupID)
            TableColumn("Local", value: \.localCatalog)
            TableColumn("Remote", value: \.offsiteCatalog)
            TableColumn("Server", value: \.offsiteServer)
            TableColumn("Date run", value: \.dateRun)
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

extension OutputTable {
    func sometablefunc() {}

    func dismissview() {
        isPresented = false
    }
}
