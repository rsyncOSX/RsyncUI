//
//  DetailsVerifyView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2024.
//

import SwiftUI

struct DetailsVerifyView: View {
    let remotedatanumbers: RemoteDataNumbers
    let push: Bool

    var body: some View {
        
        VStack(alignment: .leading) {
            
        if push {
            HStack {
                Image(systemName: "arrow.right")
                    .font(.title)
                    .imageScale(.large)
                    .foregroundColor(.yellow)
                Text("PUSH local")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            .padding()
        } else {
            HStack {
                Image(systemName: "arrow.left")
                    .font(.title)
                    .imageScale(.large)
                    .foregroundColor(.yellow)
                Text("PULL remote")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            .padding()
        }
        
            Table(remotedatanumbers.outputfromrsync ?? []) {
                TableColumn("Output from rsync" + ": \(remotedatanumbers.outputfromrsync?.count ?? 0) rows") { data in
                    Text(data.record)
                }
            }
        }
    }
}
