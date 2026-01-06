//
//  extensionTasksView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 13/12/2025.
//

import Observation
import OSLog
import SwiftUI

extension TasksView {
    @ToolbarContentBuilder
    var taskviewtoolbarcontent: some ToolbarContent {
        ToolbarItem {
            if GlobalTimer.shared.timerIsActive(),
               columnVisibility == .detailOnly {
                MessageView(mytext: GlobalTimer.shared.nextScheduleDate() ?? "", size: .caption2)
            }
        }

        ToolbarItem {
            if columnVisibility == .detailOnly {
                VStack {
                    if rsyncUIdata.validprofiles.isEmpty == false {
                        Picker("", selection: $selectedprofileID) {
                            Text("Default")
                                .tag(nil as ProfilesnamesRecord.ID?)
                            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                                Text(profile.profilename)
                                    .tag(profile.id)
                            }
                        }
                        // .frame(width: 180)
                        // .padding([.bottom, .top, .trailing], 7)
                    }

                    if SharedReference.shared.newversion {
                        MessageView(mytext: "Update available", size: .caption2)
                            .padding()
                            .frame(width: 180)
                    }
                }
            }
        }

        ToolbarItem {
            Spacer()
        }

        ToolbarItem {
            Button {
                guard SharedReference.shared.norsync == false else { return }
                guard allTasksAreHalted() == false else { return }
                // This only applies if one task is selected and that task is halted
                // If more than one task is selected, any halted tasks are ruled out
                if let selectedconfig {
                    guard selectedconfig.task != SharedReference.shared.halted else {
                        return
                    }
                }
                guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                    return
                }

                executetaskpath.append(Tasks(task: .summarizeddetailsview))
            } label: {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Color(.blue))
            }
            .help("Estimate (⌘E)")
        }

        ToolbarItem {
            Button {
                guard SharedReference.shared.norsync == false else { return }
                guard allTasksAreHalted() == false else { return }
                // This only applies if one task is selected and that task is halted
                // If more than one task is selected, any halted tasks are ruled out
                if let selectedconfig {
                    guard selectedconfig.task != SharedReference.shared.halted else {
                        return
                    }
                }

                guard selecteduuids.count > 0 || rsyncUIdata.configurations?.count ?? 0 > 0 else {
                    return
                }
                // Check if there are estimated tasks, if true execute the
                // estimated tasks view
                if progressdetails.estimatedlist?.count ?? 0 > 0 {
                    executetaskpath.append(Tasks(task: .executestimatedview))
                } else {
                    execute()
                }
            } label: {
                Image(systemName: "play.fill")
                    .foregroundColor(Color(.blue))
            }
            .help("Synchronize (⌘R)")
        }

        ToolbarItem {
            Button {
                selecteduuids.removeAll()
                reset()
            } label: {
                if thereareestimates == true {
                    Image(systemName: "clear")
                        .foregroundColor(Color(.red))
                } else {
                    Image(systemName: "clear")
                }
            }
            .help("Reset estimates")
        }

        ToolbarItem {
            Spacer()
        }

        Group {
            if showquicktask {
                ToolbarItem {
                    Button {
                        guard selecteduuids.count > 0 else { return }
                        guard allTasksAreHalted() == false else { return }

                        guard selecteduuids.count == 1 else {
                            executetaskpath.append(Tasks(task: .summarizeddetailsview))
                            return
                        }

                        if selecteduuids.count == 1 {
                            guard selectedconfig?.task != SharedReference.shared.halted else {
                                return
                            }
                        }

                        if progressdetails.tasksAreEstimated(selecteduuids) {
                            executetaskpath.append(Tasks(task: .dryrunonetaskalreadyestimated))
                        } else {
                            executetaskpath.append(Tasks(task: .onetaskdetailsview))
                        }
                    } label: {
                        Image(systemName: "text.magnifyingglass")
                    }
                    .help("Rsync output estimated task")
                }

                ToolbarItem {
                    Button {
                        executetaskpath.append(Tasks(task: .quick_synchronize))
                    } label: {
                        Image(systemName: "hare")
                    }
                    .help("Quick synchronize")
                }

                ToolbarItem {
                    Button {
                        executetaskpath.append(Tasks(task: .charts))
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    .help("Charts")
                    .disabled(selecteduuids.count != 1 || selectedconfig?.task == SharedReference.shared.syncremote)
                }

                ToolbarItem {
                    Button {
                        activeSheet = .scheduledtasksview
                    } label: {
                        Image(systemName: "calendar.circle.fill")
                    }
                    .help("Schedule")
                }

                ToolbarItem {
                    Button {
                        openWindow(id: "rsyncuilog")
                    } label: {
                        Image(systemName: "doc.plaintext")
                    }
                    .help("View logfile")
                }

                ToolbarItem {
                    Button {
                        saveactualsynclogdata.toggle()
                        SharedReference.shared.saveactualsynclogdata = saveactualsynclogdata
                    } label: {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundStyle(saveactualsynclogdata ? .green : .primary)
                    }
                    .help("Save actual synchronize log to logfile")
                }
            }
        }

        ToolbarItem {
            Spacer()
        }

        Group {
            if allTasksAreHalted() == false {
                ToolbarItem {
                    Button {
                        if urlcommandestimateandsynchronize {
                            urlcommandestimateandsynchronize = false
                        } else {
                            urlcommandestimateandsynchronize = true
                        }
                    } label: {
                        Image(systemName: "bolt.shield.fill")
                            .foregroundColor(Color(.yellow))
                    }
                    .help("Estimate & Synchronize")
                }
            }
        }
    }
}
