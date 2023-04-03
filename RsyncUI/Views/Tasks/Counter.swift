//
//  Counter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2023.
//

import SwiftUI

struct Counter: View {
    @Binding var timervalue: Double
    @Binding var execute: Bool

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(Int(timervalue / 60)) " + "minute(s)")
            .font(.largeTitle)
            .onReceive(timer) { _ in
                timervalue -= 60
                if timervalue <= 0 {
                    timer.upstream.connect().cancel()
                    execute = true
                }
            }
            .onDisappear {
                timer.upstream.connect().cancel()
            }
    }
}

struct Timervalues {
    let values: Set = [300.0, 600.0, 1800.0, 2700.0, 3600.0]
}
