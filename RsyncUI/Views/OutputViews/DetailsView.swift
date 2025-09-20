//
//  DetailsView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 07/06/2024.
//

import SwiftUI

struct DetailsView: View {
    let remotedatanumbers: RemoteDataNumbers

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                DetailsViewHeading(remotedatanumbers: remotedatanumbers)

                Spacer()

                if remotedatanumbers.datatosynchronize {
                    VStack(alignment: .leading) {
                        if SharedReference.shared.rsyncversion3 {
                            Text(remotedatanumbers.newfiles_Int == 1 ? "1 new file" : "\(remotedatanumbers.newfiles_Int) new files")
                            Text(remotedatanumbers.deletefiles_Int == 1 ? "1 file for delete" : "\(remotedatanumbers.deletefiles_Int) files for delete")
                        }
                        Text(remotedatanumbers.filestransferred_Int == 1 ? "1 file changed" : "\(remotedatanumbers.filestransferred_Int) files changed")
                        Text(remotedatanumbers.totaltransferredfilessize_Int == 1 ? "byte for transfer" : "\(remotedatanumbers.totaltransferredfilessize_Int) bytes for transfer")
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

            Table(remotedatanumbers.outputfromrsync ?? []) {
                TableColumn("Output from rsync" + ": \(remotedatanumbers.outputfromrsync?.count ?? 0) rows") { data in
                    Text(data.record)
                }
            }
        }
    }
}
