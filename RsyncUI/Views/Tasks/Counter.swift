//
//  Counter.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 03/04/2023.
//

import SwiftUI

struct Counter: View {
    @SwiftUI.Environment(\.scenePhase) var scenePhase
    @SwiftUI.Environment(\.dismiss) var dismiss

    @StateObject var deltatimeinseconds = Deltatimeinseconds()
    // Timer
    @Binding var timervalue: Double
    @Binding var timerisenabled: Bool

    let timer60 = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            if timerisenabled == false {
                Text("Timer")
                    .font(.largeTitle)
            } else {
                if timervalue <= 60 {
                    timerBelow60active
                } else {
                    timerOver60active
                }
            }

            HStack {
                if timerisenabled == false {
                    timerpicker

                    ToggleViewNolabel($timerisenabled.onChange {
                        if timerisenabled == true {
                            if Timervalues().values.contains(timervalue) {
                                SharedReference.shared.timervalue = timervalue
                            }
                        } else {
                            timervalue = SharedReference.shared.timervalue ?? 600
                        }
                    })
                }
            }

            Spacer()

            Button("Dismiss") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .onDisappear {
            timerisenabled = false
        }
        .frame(width: 200, height: 150)
    }

    var timerOver60active: some View {
        Text("\(Int(timervalue / 60)) " + "minutes")
            .font(.largeTitle)
            .onReceive(timer60) { _ in
                timervalue -= 60
                if timervalue <= 0 {
                    timer60.upstream.connect().cancel()
                }
            }
            .onDisappear {
                timer60.upstream.connect().cancel()
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
            .onReceive(timer) { _ in
                timervalue -= 1
                if timervalue <= 0 {
                    timer.upstream.connect().cancel()
                }
            }
            .onDisappear {
                timer.upstream.connect().cancel()
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

    var timerdefault: some View {
        Text("\(Int(timervalue / 60))")
            .font(.largeTitle)
            .padding()
    }

    var timerpicker: some View {
        HStack {
            Picker("", selection: $timervalue) {
                ForEach(Timervalues().values.sorted(by: <), id: \.self) { value in
                    switch value {
                    case 60.0:
                        Text("1 min")
                            .tag(value)
                    case 300.0:
                        Text("5 min")
                            .tag(value)
                    case 600.0:
                        Text("10 min")
                            .tag(value)
                    case 1800.0:
                        Text("30 min")
                            .tag(value)
                    case 2700.0:
                        Text("45 min")
                            .tag(value)
                    case 3600.0:
                        Text("1 hour")
                            .tag(value)
                    default:
                        Text(String(value))
                            .tag(value)
                    }
                }
            }
            .frame(width: 80)
            .accentColor(.blue)
        }
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

struct Timervalues {
    let values: Set = [60.0, 300.0, 600.0, 1800.0, 2700.0, 3600.0]
}

/*
 case .asynctimerison:
     Counter(timervalue: $timervalue)
         .onAppear(perform: {
             startasynctimer()
         })
         .onDisappear(perform: {
             stopasynctimer()
             timervalue = SharedReference.shared.timervalue ?? 600
             timerisenabled = false
         })
 }
 */
