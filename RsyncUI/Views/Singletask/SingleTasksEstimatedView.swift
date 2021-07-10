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
            Text("New :\(numbers.newfiles ?? 0)")
            Text("Delete: \(numbers.deletefiles ?? 0)")
            Text("Size transfer :\(numbers.transferNumSize ?? 0)")
            Text("Numbers transfer: \(numbers.transferNum ?? 0)")
            Text("Total remote numbers: \(numbers.totNum ?? 0)")
            Text("Total remote size: \(numbers.totNumSize ?? 0)")
        }
        .padding()
    }
}
