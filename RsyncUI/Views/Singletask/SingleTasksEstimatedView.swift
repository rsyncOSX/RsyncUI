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
            .border(Color.blue)
    }

    var numbers: Numbers {
        return Numbers(output)
    }

    var numberstopresent: some View {
        HStack {
            Text("New: \(numbers.newfiles ?? 0)")
            Text("Delete: \(numbers.deletefiles ?? 0)")
            Text("Size transfer: " + String(format: "%.2f", ((numbers.transferNumSize ?? 0) / 1024) / 1000) + " MB")
            Text("Numbers transfer: \(numbers.transferNum ?? 0)")
            Text("Total remote numbers: \(numbers.totNum ?? 0)")
            Text("Total remote size: " + String(format: "%.2f", ((numbers.totNumSize ?? 0) / 1024) / 1000) + " MB")
        }
        .padding()
    }
}
