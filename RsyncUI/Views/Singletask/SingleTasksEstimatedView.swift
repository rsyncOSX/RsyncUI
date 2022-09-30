//
//  SingleTasksEstimatedView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/07/2021.
//
import SwiftUI

struct SingleTasksEstimatedView: View {
    var output: [String]

    var body: some View {
        numberstopresent
            .padding()
    }

    var remoteinfonumbers: RemoteinfoNumbers {
        return RemoteinfoNumbers(data: output)
        // return Numbers(output)
    }

    var numberstopresent: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("New files" + ": ")
                Text("Delete files" + ": ")
                Text("KB to be transferred" + ": ")
                Text("")
                Text("Number of files" + ": ")
                Text("Total size (kB)" + ": ")
            }
            VStack(alignment: .trailing) {
                Text(remoteinfonumbers.newfiles ?? "")
                Text(remoteinfonumbers.deletefiles ?? "")
                Text(remoteinfonumbers.transferredNumberSizebytes ?? "")
                Text("")
                Text(remoteinfonumbers.totalNumber ?? "")
                Text(remoteinfonumbers.totalNumberSizebytes ?? "")
            }
        }
    }
}
