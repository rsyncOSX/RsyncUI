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
            if columnVisibility == .detailOnly {
                VStack {
                    if rsyncUIdata.validprofiles.isEmpty == false {
                        Picker("Profile", selection: $selectedprofileID) {
                            Text("Default")
                                .tag(nil as ProfilesnamesRecord.ID?)
                            ForEach(rsyncUIdata.validprofiles, id: \.self) { profile in
                                Text(profile.profilename)
                                    .tag(profile.id)
                            }
                        }
                        .labelsHidden()
                    }

                    if SharedReference.shared.newversion {
                        MessageView(mytext: String(localized: "Update available"), size: .caption2)
                            .padding()
                            .frame(width: 180)
                    }
                }
            }
        }

        ToolbarItemGroup(placement: .automatic) {
            Button {
                urlcommandestimateandsynchronize.toggle()
            } label: {
                Label("Estimate & Sync", systemImage: "bolt.shield.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color.accentColor)
            }
            .help("Estimate & Synchronize")
            .disabled(allTasksAreHalted())
        }

        ToolbarItem {
            Button {
                selecteduuids.removeAll()
                reset()
            } label: {
                Label("Reset", systemImage: "clear")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(thereareestimates ? Color(.red) : .primary)
            }
            .help("Reset estimates")
        }

        Group {
            if showquicktask {
                ToolbarItem {
                    Menu {
                        Button {
                            guard selecteduuids.count > 0, allTasksAreHalted() == false else { return }

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
                            Label("Rsync output estimated task", systemImage: "text.magnifyingglass")
                        }

                        Button {
                            executetaskpath.append(Tasks(task: .quick_synchronize))
                        } label: {
                            Label("Quick synchronize", systemImage: "hare")
                        }

                        Button {
                            executetaskpath.append(Tasks(task: .charts))
                        } label: {
                            Label("Charts", systemImage: "chart.bar.fill")
                        }
                        .disabled(selecteduuids.count != 1 || selectedconfig?.task == SharedReference.shared.syncremote)

                        Divider()

                        Button {
                            openWindow(id: "rsyncuilog")
                        } label: {
                            Label("View logfile", systemImage: "doc.plaintext")
                        }

                        Button {
                            saveactualsynclogdata.toggle()
                            SharedReference.shared.saveactualsynclogdata = saveactualsynclogdata
                        } label: {
                            Label("Save sync log to log file", systemImage: "square.and.arrow.down.fill")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                            .labelStyle(.iconOnly)
                    }
                    .help("More synchronize actions")
                }
            }
        }
    }
}
