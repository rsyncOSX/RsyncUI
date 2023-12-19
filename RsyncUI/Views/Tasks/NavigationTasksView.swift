//
//  NavigationTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 10/11/2023.
//

import Observation
import OSLog
import SwiftUI

struct CopyItem: Identifiable, Codable, Transferable {
    let id: UUID
    let hiddenID: Int
    let task: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

enum TypeofTask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case snapshot
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

@Observable
final class Selectedconfig {
    var config: Configuration?
}

enum Sheet: String, Identifiable {
    case dryrunalltasks, dryrunalreadyestimated, dryrunonetask, alltasksview, firsttime, asynctimerison
    var id: String { rawValue }
}

struct NavigationTasksView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    // The object holds the progressdata for the current estimated task
    // which is executed. Data for progressview.
    @EnvironmentObject var executeprogressdetails: ExecuteProgressDetails

    @Bindable var estimateprogressdetails: EstimateProgressDetails
    @Binding var reload: Bool
    @Binding var selecteduuids: Set<Configuration.ID>
    // Navigation path
    @Binding var path: [Tasks]

    @State private var estimatingstate = EstimatingState()
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
            ListofTasksMainView(
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
                estimateprogressdetails.uuids = selecteduuids
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
                        .foregroundColor(Color(.blue))
                }
                .help("Estimate (⌘E)")
            }

            ToolbarItem {
                Button {
                    execute()
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .foregroundColor(Color(.blue))
                }
                .help("Synchronize (⌘R)")
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
                    if estimateprogressdetails.tasksareestimated(selecteduuids) {
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

            ToolbarItem {
                Button {
                    path.append(Tasks(task: .viewlogfile))
                } label: {
                    Image(systemName: "filemenu.and.cursorarrow")
                }
                .help("View logfile")
            }
        })
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Synchronize all tasks with NO estimating first?"),
                primaryButton: .default(Text("Synchronize")) {
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
        if estimateprogressdetails.getestimatedlist() == nil {
            dryrun()
        } else if estimateprogressdetails.tasksareestimated(selecteduuids) {
            execute()
        } else {
            dryrun()
        }
    }

    func dryrun() {
        if selectedconfig.config != nil,
           estimateprogressdetails.getestimatedlist()?.count ?? 0 == 0
        {
            Logger.process.info("DryRun: execute a dryrun for one task only")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        } else if selectedconfig.config != nil,
                  estimateprogressdetails.executeanotherdryrun(rsyncUIdata.profile ?? "Default profile") == true
        {
            Logger.process.info("DryRun: new task same profile selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))

        } else if selectedconfig.config != nil,
                  estimateprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == false
        {
            Logger.process.info("DryRun: profile is changed, new task selected, execute a dryrun")
            doubleclick = false
            path.append(Tasks(task: .dryrunonetask))
        }
    }

    func execute() {
        // All tasks are estimated and ready for execution.
        if selecteduuids.count == 0,
           estimateprogressdetails.alltasksestimated(rsyncUIdata.profile ?? "Default profile") == true

        {
            Logger.process.info("Execute() all estimated tasks")
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))

        } else if selecteduuids.count >= 1,
                  estimateprogressdetails.tasksareestimated(selecteduuids) == true

        {
            // One or some tasks are selected and estimated
            Logger.process.info("Execute() estimated tasks only")
            // Execute estimated tasks only
            // Execute all estimated tasks
            selecteduuids = estimateprogressdetails.getuuids()
            estimatingstate.updatestate(state: .start)
            // Change view, see SidebarTasksView
            path.append(Tasks(task: .executestimatedview))
        } else {
            // Execute all tasks, no estimate
            Logger.process.info("Execute() selected or all tasks NO estimate")
            // Execute tasks, no estimate
            showingAlert = true
            // path.append(Tasks(task: .executenoestimatetasksview))
            // path.append in Showing alert
        }
    }

    func reset() {
        executeprogressdetails.resetcounts()
        estimateprogressdetails.resetcounts()
        estimatingstate.updatestate(state: .start)
        selectedconfig.config = nil
    }

    func abort() {
        executeprogressdetails.resetcounts()
        estimateprogressdetails.resetcounts()
        selecteduuids.removeAll()
        estimatingstate.updatestate(state: .start)
        _ = InterruptProcess()
        reload = true
        focusstartestimation = false
        focusstartexecution = false
    }
}
