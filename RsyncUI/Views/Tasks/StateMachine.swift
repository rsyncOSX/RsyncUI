//
//  StateMachine.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/06/2025.
//

import Foundation

enum StateTask {
    case noselecteduuid

    case oneselecteduuid
    case changedselecteduuid
    case severalselecteduuid

    case dryrunONEtaskready
    case dryrunNOtaskready
    case dryrynSEVERALtasksready

    case doubleclick
    case doubleclicknewtask

    case readyforexecute
}

enum Event {
    case start
    case dryrun
    case execute
    case resetestimates
}

@MainActor
final class StateMachine {
    
    private(set) var state: StateTask = .noselecteduuid

    func handle(event: Event) {
        
        switch (state, event) {
            
        // Dry run by double click, first double click executes dry-run
        // second double click the real synchronization of data.
        // If user select another task, by double clik, a new dry-run
        case (.oneselecteduuid, .start), (.doubleclick, .start):
            state = .dryrunONEtaskready
            print("One task selected FIRST DOUBLE CLICK, ready for dryrun")
        case (.doubleclicknewtask, .start):
            state = .dryrunONEtaskready
            print("One task selected FIRST DOUBLE CLICK, NEW task selected, ready for dryrun")
        case (.doubleclick, .dryrun):
            state = .readyforexecute
            print("One task selected SECOND DOUBLE CLICK , ready for execute")
        
        // Selected some tasks, execute dry-run by Magic Wand on toolbar
        // Only pick seleected tasks for dry-run.
        // When dry-run completed ready for the real synchronization of data for estimated tasks
        case (.severalselecteduuid, .start):
            state = .dryrynSEVERALtasksready
            print("SEVERAL (but not all) tasks selected, ready for dryrun")
        case (.severalselecteduuid, .dryrun):
            state = .readyforexecute
            print("SEVERAL (but not all) tasks selected, dryrun completed, ready for execute")
        case (.severalselecteduuid, .execute):
            state = .readyforexecute
            print("SEVERAL (but not all) tasks selected, NO dryrun ready for execute")
        
        // No tasks selected, execute dry-run for all tasks
        // When dry-run completed ready for the real synchronization of data for all estimated tasks
        case (.noselecteduuid, .start):
            state = .dryrynSEVERALtasksready
            print("Several tasks selected, ready for dryrun")
        case (.noselecteduuid, .dryrun):
            state = .readyforexecute
            print("ALL tasks selected, dryrun completed, ready for execute")
        case (.noselecteduuid, .execute):
            state = .readyforexecute
            print("ALL tasks selected, NO dryrun ready for execute ")
        
    
        case (.severalselecteduuid, .resetestimates),
            (.oneselecteduuid, .resetestimates),
            (.noselecteduuid, .resetestimates):
            state = .noselecteduuid
            print("RESET")
        
        
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
