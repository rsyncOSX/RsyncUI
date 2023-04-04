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

    let timer1 = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    let timer2 = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if timervalue <= 60 {
            timerBelow60active
        } else {
            timerOver60active
        }
    }

    var timerOver60active: some View {
        Text("\(Int(timervalue / 60)) " + "minute(s)")
            .font(.largeTitle)
            .onReceive(timer1) { _ in
                timervalue -= 60
                if timervalue <= 0 {
                    timer1.upstream.connect().cancel()
                    execute = true
                }
            }
            .onDisappear {
                timer1.upstream.connect().cancel()
            }
    }

    var timerBelow60active: some View {
        Text("\(Int(timervalue)) " + "seconds")
            .font(.largeTitle)
            .onReceive(timer2) { _ in
                timervalue -= 1
                if timervalue <= 0 {
                    timer2.upstream.connect().cancel()
                    execute = true
                }
            }
            .onDisappear {
                timer2.upstream.connect().cancel()
            }
    }
}

struct Timervalues {
    let values: Set = [60.0, 300.0, 600.0, 1800.0, 2700.0, 3600.0]
}
