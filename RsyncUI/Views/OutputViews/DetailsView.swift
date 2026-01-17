//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/06/2024.
//

import RsyncAnalyse
import SwiftUI

struct DetailsView: View {
    let remotedatanumbers: RemoteDataNumbers
    let itemizechanges: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                DetailsViewHeading(remotedatanumbers: remotedatanumbers)

                Spacer()

                if remotedatanumbers.datatosynchronize {
                    VStack(alignment: .leading) {
                        if SharedReference.shared.rsyncversion3 {
                            Text(remotedatanumbers.newfilesInt == 1 ? "1 new file" : "\(remotedatanumbers.newfilesInt) new files")
                            let deleteText = remotedatanumbers.deletefilesInt == 1
                                ? "1 file for delete"
                                : "\(remotedatanumbers.deletefilesInt) files for delete"
                            Text(deleteText)
                        }
                        let filesChangedText = remotedatanumbers.filestransferredInt == 1
                            ? "1 file changed"
                            : "\(remotedatanumbers.filestransferredInt) files changed"
                        Text(filesChangedText)
                        let transferSizeText = remotedatanumbers.totaltransferredfilessizeInt == 1
                            ? "byte for transfer"
                            : "\(remotedatanumbers.totaltransferredfilessize) bytes for transfer"
                        Text(transferSizeText)
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue.gradient)
                    }
                    .padding()

                } else {
                    Text("No data to synchronize")
                        .font(.title2)
                        .padding()
                        .foregroundStyle(.white)
                        .background {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue.gradient)
                        }
                        .padding()
                }
            }

            if let records = remotedatanumbers.outputfromrsync {
                if itemizechanges {
                    Table(records) {
                        TableColumn("Output from rsync (\(records.count) rows)") { data in
                            RsyncOutputRowView(record: data.record)
                        }
                    }
                } else {
                    Table(records) {
                        TableColumn("Output from rsync (\(records.count) rows)") { data in
                            Text(data.record)
                        }
                    }
                }
            } else {
                Text("No rsync output available")
                    .foregroundColor(.secondary)
            }
        }
    }
}
