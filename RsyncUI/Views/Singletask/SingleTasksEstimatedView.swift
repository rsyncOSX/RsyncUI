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

    var numbers: Numbers {
        return Numbers(output)
    }

    var numberstopresent: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("New: ")
                Text("Delete: ")
                Text("Numbers transfer: ")
                Text("Size transfer: ")
                Text("")
                Text("Total remote numbers: ")
                Text("Total remote size: ")
            }
            VStack(alignment: .trailing) {
                Text("\(numbers.newfiles ?? 0)")
                Text("\(numbers.deletefiles ?? 0)")
                Text("\(numbers.transferNum ?? 0)")
                Text(String(format: "%.2f", ((numbers.transferNumSize ?? 0) / 1024) / 1000) + " MB")
                Text("")
                Text("\(numbers.totNum ?? 0)")
                Text(String(format: "%.2f", ((numbers.totNumSize ?? 0) / 1024) / 1000) + " MB")
            }
        }
    }
}
