//
//  Counter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2023.
//

import SwiftUI

struct Counter: View {
    @Binding var count: Double
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(Int(count / 60)) " + "minutes")
            .font(.largeTitle)
            .onReceive(timer) { _ in
                count -= 60
                if count <= 0 {
                    timer.upstream.connect().cancel()
                }
            }
    }

    var timervalue: Double {
        switch count {
        case 300:
            return 30
        case 600:
            return 60
        case 1800:
            return 180
        case 2700:
            return 270
        case 3600:
            return 360
        default:
            return 60
        }
    }
}

struct Timervalues {
    let values: Set = [300.0, 600.0, 1800.0, 2700.0, 3600.0]
}
