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
    case noselecteduuid
    case oneselecteduuid
    case changedselecteduuid
    case severalselecteduuid
    case tasksisestimated
}

enum Event {
    case start
    case dryrun
    case execute
    case resetestimates
}

class StateMachine {
    
    private(set) var state: State = .noselecteduuid

    func handle(event: Event) {
        switch (state, event) {
        case (.noselecteduuid, .start):
            state = .oneselecteduuid
            print("Transition: idle -> loading")
        case (.oneselecteduuid, .dryrun):
            state = .severalselecteduuid
            print("Transition: loading -> success")
        case (.oneselecteduuid, .execute):
            state = .changedselecteduuid
            print("Transition: loading -> failure")
        case (.severalselecteduuid, .resetestimates), (.changedselecteduuid, .resetestimates):
            state = .noselecteduuid
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

/*
  
  func dryrun() {
      if selectedconfig.config != nil,
         progressdetails.estimatedlist?.count ?? 0 == 0,
         selectedtaskishalted == false
      {
          Logger.process.info("DryRun: execute a dryrun for one task only")
          doubleclick = false
          path.append(Tasks(task: .onetaskdetailsview))
      } else if selectedconfig.config != nil,
                progressdetails.executeanotherdryrun(rsyncUIdata.profile) == true
      {
          Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
          doubleclick = false
          path.append(Tasks(task: .onetaskdetailsview))

      } else if selectedconfig.config != nil,
                progressdetails.alltasksestimated(rsyncUIdata.profile) == false
      {
          Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
          doubleclick = false
          path.append(Tasks(task: .onetaskdetailsview))
      }
  }

  func execute() {
      // All tasks are estimated and ready for execution.
      rsyncUIdata.executetasksinprogress = true
      if selecteduuids.count == 0,
         progressdetails.alltasksestimated(rsyncUIdata.profile) == true
      {
          Logger.process.info("Execute() all estimated tasks")
          // Execute all estimated tasks
          selecteduuids = progressdetails.getuuidswithdatatosynchronize()
          estimatestate.updateestimatestate(state: .start)
          // Change view, see SidebarTasksView
          path.append(Tasks(task: .executestimatedview))

      } else if selecteduuids.count >= 1,
                progressdetails.tasksareestimated(selecteduuids) == true

      {
          // One or some tasks are selected and estimated
          Logger.process.info("Execute() estimated tasks only")
          // Execute estimated tasks only
          selecteduuids = progressdetails.getuuidswithdatatosynchronize()
          estimatestate.updateestimatestate(state: .start)
          // Change view, see SidebarTasksView
          path.append(Tasks(task: .executestimatedview))
      } else {
          // Execute all tasks, no estimate
          Logger.process.info("Execute() selected or all tasks NO estimate")
          // Execute tasks, no estimate
          showingAlert = true
      }
  }
 */
