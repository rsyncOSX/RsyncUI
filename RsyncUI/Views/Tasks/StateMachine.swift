//
//  StateMachine.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 06/06/2025.
//

import Foundation

enum Waiting {}
enum CoinInserted {}
enum Fetching {}
enum Serving {}


enum NoTaskIsSelected {}
enum TaskisReSelected {}
enum OneTaskIsSelected {}
enum DoubleClickDiscovered {}
enum TasksAreEstimated {}
enum NoTasksAreEstimated {}

struct Transition<From, To> {}

struct Machine<State> {
    func transition<To>(with transition: Transition<State, To>) -> Machine<To> {
        .init()
    }
}

final class StateMachine {
    
    let readyfordryrun = Transition<NoTaskIsSelected, OneTaskIsSelected>()
    let readyfornewdryrun = Transition<TaskisReSelected, OneTaskIsSelected>()
    
    
    
    
    let start = Transition<Waiting, CoinInserted>()
    let selectionMade = Transition<CoinInserted, Fetching>()
    let delivery = Transition<Fetching, Serving>()
    let reset = Transition<Serving, Waiting>()
    
    
    init () {
        let ready = Machine<NoTaskIsSelected>()
        
        
        
        let m1 = Machine<Waiting>()
        let m2 = m1.transition(with: start)
        let m3 = m2.transition(with: selectionMade)
        let m4 = m3.transition(with: delivery)
        let m5 = m4.transition(with: reset)
        
        // Will not compile
        // let m6 = m5.transition(with: delivery)
    }
    
}


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

 
 ToolbarItem {
     Button {
         guard SharedReference.shared.norsync == false else { return }
         guard alltasksarehalted() == false else { return }
         guard selectedtaskishalted == false else { return }

         guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
             Logger.process.info("Estimate() no tasks selected, no configurations, bailing out")
             return
         }
         execute()
     } label: {
         Image(systemName: "play.fill")
             .foregroundColor(Color(.blue))
     }
     .help("Synchronize (⌘R)")
 }
 
 var labelstartexecution: some View {
     Label("", systemImage: "play.fill")
         .foregroundColor(.black)
         .onAppear(perform: {
             execute()
             focusstartexecution = false
         })
 }
 
 
 if focusstartexecution { labelstartexecution }
 
 */
