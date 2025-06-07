//
//  StateMachine.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/06/2025.
//

import Foundation

enum TrafficLightState {
    case red
    case yellow
    case green
}

enum TrafficLightEvent {
    case timer
}

class TrafficLightStateMachine {
    private(set) var state: TrafficLightState

    init(initialState: TrafficLightState) {
        self.state = initialState
    }

    func handle(event: TrafficLightEvent) {
        switch (state, event) {
        case (.red, .timer):
            state = .green
            print("Transitioning from RED to GREEN")
        case (.green, .timer):
            state = .yellow
            print("Transitioning from GREEN to YELLOW")
        case (.yellow, .timer):
            state = .red
            print("Transitioning from YELLOW to RED")
        default:
            print("No transition available for state \(state) with event \(event)")
        }
    }
}
/*
// Example Usage
let trafficLight = TrafficLightStateMachine(initialState: .red)
trafficLight.handle(event: .timer) // RED -> GREEN
trafficLight.handle(event: .timer) // GREEN -> YELLOW
trafficLight.handle(event: .timer) // YELLOW -> RED
*/


import Foundation

enum State {
    case idle
    case loading
    case success
    case failure
}

enum Event {
    case start
    case succeed
    case fail
    case reset
}

class StateMachine {
    private(set) var state: State = .idle

    func handle(event: Event) {
        switch (state, event) {
        case (.idle, .start):
            state = .loading
            print("Transition: idle -> loading")
        case (.loading, .succeed):
            state = .success
            print("Transition: loading -> success")
        case (.loading, .fail):
            state = .failure
            print("Transition: loading -> failure")
        case (.success, .reset), (.failure, .reset):
            state = .idle
            print("Transition: \(state) -> idle")
        default:
            print("No transition for (\(state), \(event))")
        }
    }
}
/*
// Example usage:
let machine = StateMachine()
machine.handle(event: .start)    // idle -> loading
machine.handle(event: .succeed)  // loading -> success
machine.handle(event: .reset)    // success -> idle
machine.handle(event: .start)    // idle -> loading
machine.handle(event: .fail)     // loading -> failure
machine.handle(event: .reset)    // failure -> idle
*/
