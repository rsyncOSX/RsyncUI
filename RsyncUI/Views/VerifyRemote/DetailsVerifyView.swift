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
                        .font(.title2)
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
                        .font(.title2)
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
                    if data.record.contains("*deleting") {
                        HStack {
                            Text("delete").foregroundColor(.red)
                            Text(data.record)
                        }
                        
                    } else if data.record.contains("<"){
                        HStack {
                            Text("push").foregroundColor(.blue)
                            Text(data.record)
                        }
                        
                    } else if data.record.contains(">"){
                        HStack {
                            Text("pull").foregroundColor(.green)
                            Text(data.record)
                        }
                    } else {
                        Text(data.record)
                    }
                }
            }
        }
    }
}
