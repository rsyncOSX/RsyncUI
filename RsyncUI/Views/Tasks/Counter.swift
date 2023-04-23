//
//  Counter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2023.
//

import SwiftUI

struct Counter: View {
    @SwiftUI.Environment(\.scenePhase) var scenePhase
    @StateObject var deltatimeinseconds = Deltatimeinseconds()
    @Binding var timervalue: Double
    @Binding var isPresented: Bool

    let timer1 = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    let timer2 = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        if timervalue <= 60 {
            timerBelow60active
                .padding()
        } else {
            timerOver60active
                .padding()
        }
        Spacer()

        HStack {
            Spacer()

            Button("Dismiss") { dismissview() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }

    var timerOver60active: some View {
        Text("\(Int(timervalue / 60)) " + "minutes")
            .font(.largeTitle)
            .onReceive(timer1) { _ in
                timervalue -= 60
                if timervalue <= 0 {
                    timer1.upstream.connect().cancel()
                }
            }
            .onDisappear {
                timer1.upstream.connect().cancel()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    deltatimeinseconds.timerminimized = Date()
                } else if newPhase == .active {
                    deltatimeinseconds.computeminimizedtime()
                    // _ = Logfile(["Active again - \(deltatimeinseconds.sleeptime) seconds minimized"], error: true)
                } else if newPhase == .background {}
            }
    }

    var timerBelow60active: some View {
        Text("\(Int(timervalue)) " + "seconds")
            .font(.largeTitle)
            .onReceive(timer2) { _ in
                timervalue -= 1
                if timervalue <= 0 {
                    timer2.upstream.connect().cancel()
                }
            }
            .onDisappear {
                timer2.upstream.connect().cancel()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .inactive {
                    if deltatimeinseconds.timerminimized == nil {
                        deltatimeinseconds.timerminimized = Date()
                    }
                } else if newPhase == .active {
                    deltatimeinseconds.computeminimizedtime()
                    // _ = Logfile(["Active again - \(deltatimeinseconds.sleeptime) seconds minimized"], error: true)
                } else if newPhase == .background {}
            }
    }
}

extension Counter {
    func dismissview() {
        isPresented = false
    }
}

final class Deltatimeinseconds: ObservableObject {
    var timerstart: Date = .init()
    var timerminimized: Date?
    var sleeptime: Double = 0

    func computeminimizedtime() {
        if let timerminimized = timerminimized {
            let now = Date()
            if sleeptime == 0 {
                sleeptime = now.timeIntervalSinceReferenceDate - timerminimized.timeIntervalSinceReferenceDate
            } else {
                sleeptime += (now.timeIntervalSinceReferenceDate - timerminimized.timeIntervalSinceReferenceDate)
            }
        }
    }

    func resetdates() {}
}
