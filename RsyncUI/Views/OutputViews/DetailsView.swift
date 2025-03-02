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
                        Text("^[\(remotedatanumbers.newfiles_Int) file](inflect: true) new")
                        Text("^[\(remotedatanumbers.deletefiles_Int) file](inflect: true) for delete")
                        Text("^[\(remotedatanumbers.filestransferred_Int) file](inflect: true) changed")
                        Text("^[\(remotedatanumbers.transferredNumberSizebytes_Int) byte](inflect: true) for transfer")
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
