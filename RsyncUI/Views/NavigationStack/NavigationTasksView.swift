//
//  NavigationTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct NavigationTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var progressdetails: ExecuteProgressDetails

    @Bindable var estimatingprogressdetails: EstimateProgressDetails
    @State private var estimatingstate = EstimatingState()
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    @Binding var path: [Tasks]
    // Focus buttons from the menu
    @State private var focusstartestimation: Bool = false
    @State private var focusstartexecution: Bool = false
    // Filterstring
    @State private var filterstring: String = ""
    // Local data for present local and remote info about task
    @State private var localdata: [String] = []
    @State var selectedconfig = Selectedconfig()
    // Double click, only for macOS13 and later
    @State private var doubleclick: Bool = false
    // Alert button
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            NavigationListofTasksMainView(
                selecteduuids: $selecteduuids,
                filterstring: $filterstring,
                reload: $reload,
                doubleclick: $doubleclick
            )
            .frame(maxWidth: .infinity)
            .onChange(of: selecteduuids) {
                let selected = rsyncUIdata.configurations?.filter { config in
                    selecteduuids.contains(config.id)
                }
                if (selected?.count ?? 0) == 1 {
                    if let config = selected {
                        selectedconfig.config = config[0]
                    }
                } else {
                    selectedconfig.config = nil
                }
                estimatingprogressdetails.uuids = selecteduuids
            }

            Group {
                if focusstartestimation { labelstartestimation }
                if focusstartexecution { labelstartexecution }
                if doubleclick { doubleclickaction }
            }
        }
        .focusedSceneValue(\.startestimation, $focusstartestimation)
        .focusedSceneValue(\.startexecution, $focusstartexecution)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    path.append(Tasks(task: .estimatedview))
                } label: {
                    Image(systemName: "wand.and.stars")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.blue, .blue)
                }
                .help("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.backward")
                }
                .help("Execute (⌘R)")
            }

            ToolbarItem {
                Button {
                    selecteduuids.removeAll()
                    reset()
                } label: {
                    Image(systemName: "eraser")
                }
                .help("Reset estimates")
            }

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .alltasksview))
                } label: {
                    Image(systemName: "list.bullet")
                }
                .help("List tasks all profiles")
            }

            ToolbarItem {
                Button {
                    guard selecteduuids.count > 0 else { return }
                    if estimatingprogressdetails.tasksareestimated(selecteduuids) {
                        Logger.process.info("Info: view details for already estimated and selected task")
                        path.append(Tasks(task: .dryrunonetaskalreadyestimated))
                    } else {
                        Logger.process.info("Info: iniate an execute for dryrun to view details for selected task")
                        path.append(Tasks(task: .dryrunonetask))
                    }
                } label: {
                    Image(systemName: "info")
                }
                .help("Rsync output estimated task")
            }
        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Execute all tasks with NO estimating first?"),
                primaryButton: .default(Text("Execute")) {
                    path.append(Tasks(task: .executenoestimatetasksview))
                },
                secondaryButton: .cancel()
            )
        }
    }

    var doubleclickaction: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                doubleclickactionfunction()
                doubleclick = false
            })
    }

    var labelstartestimation: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                path.append(Tasks(task: .estimatedview))
                focusstartestimation = false
            })
    }

    var labelstartexecution: some View {
        Label("", systemImage: "play.fill")
            .foregroundColor(.black)
            .onAppear(perform: {
                execute()
                focusstartexecution = false
            })
    }
}

extension NavigationTasksView {
    func doubleclickactionfunction() {
        if estimatingprogressdetails.getestimatedlist() == nil {
            dryrun()
        } else if estimatingprogressdetails.tasksareestimated(selecteduuids) {
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimatingprogressdetails.getestimatedlist()?.count ?? 0 == 0
        {
            Logger.process.info("DryRun: execute a dryrun for one task only")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        } else if selectedconfig.config != nil,
                  estimatingprogressdetails.executeanotherdryrun(rsyncUIdata.profile ?? "Default profile") == true
        {
            Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))

        } else if selectedconfig.config != nil,
                  estimatingprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        }
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimatingprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = estimatingprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  estimatingprogressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimatingprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))
        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showingAlert = true
            // path.append(Tasks(task: .executenoestimatetasksview))
        }
    }

    func reset() {
        progressdetails.resetcounter()
        estimatingprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
    }

    func abort() {
        progressdetails.resetcounter()
        estimatingprogressdetails.resetcounts()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
        focusstartexecution = false
    }
}
