//
//  DetailsPullPushView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2024.
//

import SwiftUI

struct DetailsPullPushView: View {
    let remotedatanumbers: RemoteDataNumbers
    let text: String

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(text)
                    .font(.title2)
                    .padding()
                
                DetailsViewHeading(remotedatanumbers: remotedatanumbers)

                Spacer()
                
                VStack(alignment: .leading) {
                    Text("^[\(remotedatanumbers.newfiles_Int) file](inflect: true) new")
                    Text("^[\(remotedatanumbers.deletefiles_Int) file](inflect: true) for delete")
                    Text("^[\(remotedatanumbers.transferredNumber_Int) file](inflect: true) changed")
                    Text("^[\(remotedatanumbers.transferredNumberSizebytes_Int) byte](inflect: true) for transfer")
                }
                .padding()
                .foregroundStyle(.white)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.gradient)
                }
                .padding()

            }

            Table(remotedatanumbers.outputfromrsync ?? []) {
                TableColumn("Output from rsync") { data in
                    Text(data.record)
                }
            }
        }
    }
}
