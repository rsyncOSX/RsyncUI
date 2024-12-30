//
//  TimerView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 29/12/2024.
//

import SwiftUI

struct TimerView: View {
    @Environment(\.dismiss) var dismiss

    @Bindable var executeprogressdetails: ExecuteProgressDetails
    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var path: [Tasks]

    @State var startDate = Date.now
    // @State var timeElapsed: Int = 0
    @State var timetosynchronize: Int = 5

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            Text("Counting down: \(timetosynchronize)")
                .onReceive(timer) { firedDate in
                    // timeElapsed = Int(firedDate.timeIntervalSince(startDate))
                    timetosynchronize -= Int(firedDate.timeIntervalSince(startDate))
                    if timetosynchronize < 0 {
                        executeprogressdetails.estimatedlist = estimateprogressdetails.estimatedlist
                        path.removeAll()
                        path.append(Tasks(task: .executestimatedview))
                    }
                }
                .padding()
                .font(.largeTitle)
                .foregroundColor(.blue)

            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(ColorfulButtonStyle())
        }
    }
}
