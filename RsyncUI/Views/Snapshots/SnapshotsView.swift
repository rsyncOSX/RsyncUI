//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct SnapshotsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var snapshotdata = SnapshotData()

    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var snapshotrecords: LogrecordSnapshot?
    @State private var selectedconfiguuid = Set<Configuration.ID>()
    // If not a snapshot
    @State private var notsnapshot = false
    // Plan for tagging and administrating snapshots
    @State private var snaplast: String = PlanSnapshots.Last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.Sunday.rawValue
    // Update plan and snapday
    @State private var updated: Bool = false
    // Confirm delete
    @State private var confirmdeletesnapshots = false
    // Alert for delete
    @State private var showAlertfordelete = false
    // Focus buttons from the menu
    @State private var focustagsnapshot: Bool = false
    @State private var focusaborttask: Bool = false
    // Delete
    @State private var confirmdelete: Bool = false

    var body: some View {
        ZStack {
            HStack {
                ListofTasksLightView(
                    selecteduuids: $selectedconfiguuid.onChange {
                        let selected = rsyncUIdata.configurations?.filter { config in
                            selectedconfiguuid.contains(config.id)
                        }
                        if (selected?.count ?? 0) == 1 {
                            if let config = selected {
                                selectedconfig = config[0]
                                getdata()
                            }
                        } else {
                            selectedconfig = nil
                            snapshotdata.setsnapshotdata(nil)
                        }
                    }
                )

                SnapshotListView(snapshotrecords: $snapshotrecords)
                    .environmentObject(snapshotdata)
            }

            if snapshotdata.snapshotlist { AlertToast(displayMode: .alert, type: .loading) }
            if notsnapshot == true { notasnapshottask }
        }

        if updated == true { notifyupdated }
        if focustagsnapshot == true { labeltagsnapshot }
        if focusaborttask { labelaborttask }

        HStack {
            Button("Save") { updateplansnapshot() }
                .buttonStyle(ColorfulButtonStyle())

            VStack(alignment: .leading) {
                pickersnaplast

                pickersnapdayoffweek
            }

            labelnumberoflogs

            Spacer()

            Group {
                if snapshotdata.inprogressofdelete == true { progressdelete }
                if snapshotdata.state == .getdata { AlertToast(displayMode: .alert, type: .loading) }
            }

            Spacer()

            Button("Delete") { showAlertfordelete = true }
                .sheet(isPresented: $showAlertfordelete) {
                    ConfirmDeleteSnapshots(delete: $confirmdeletesnapshots,
                                           snapshotuuidsfordelete: snapshotdata.snapshotuuidsfordelete)
                        .onDisappear { delete() }
                }
                .buttonStyle(ColorfulRedButtonStyle())

            Button("Abort") { abort() }
                .buttonStyle(ColorfulRedButtonStyle())
        }
        .focusedSceneValue(\.tagsnapshot, $focustagsnapshot)
        .focusedSceneValue(\.aborttask, $focusaborttask)
    }

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Number of logrecords", comment: "") +
                ": " + "\(snapshotdata.logrecordssnapshot?.count ?? 0)")
            Text(NSLocalizedString("Number to delete", comment: "") +
                ": " + "\(snapshotdata.snapshotuuidsfordelete.count)")
        }
    }

    var notasnapshottask: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text("Not a snapshot task")
                .font(.title3)
                .foregroundColor(Color.accentColor)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
        .onAppear {
            snapshotdata.state = .gotit
        }
    }

    var pickersnapdayoffweek: some View {
        Picker("",
               selection: $snapdayofweek)
        {
            ForEach(StringDayofweek.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var pickersnaplast: some View {
        Picker("",
               selection: $snaplast)
        {
            ForEach(PlanSnapshots.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var notifyupdated: some View {
        notifymessage("Updated")
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    updated = false
                }
            })
            .frame(maxWidth: .infinity)
    }

    var progressdelete: some View {
        ProgressView("",
                     value: Double(snapshotdata.remainingsnapshotstodelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 25.0, height: 25.0)
            .contentShape(Rectangle())
            .onDisappear(perform: {
                getdata()
            })
    }

    var labeltagsnapshot: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focustagsnapshot = false
                tagsnapshots()
            })
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension SnapshotsView {
    func abort() {
        snapshotdata.state = .start
        snapshotdata.setsnapshotdata(nil)
        snapshotdata.delete?.snapshotcatalogstodelete = nil
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func getdata() {
        snapshotdata.snapshotuuidsfordelete.removeAll()
        guard SharedReference.shared.process == nil else { return }
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else {
                notsnapshot = true
                // Show added for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    notsnapshot = false
                }
                return
            }
            // Setting values for tagging snapshots
            if let snaplast = config.snaplast {
                if snaplast == 0 {
                    self.snaplast = PlanSnapshots.Last.rawValue
                } else {
                    self.snaplast = PlanSnapshots.Every.rawValue
                }
            }
            if let snapdayofweek = config.snapdayoffweek {
                self.snapdayofweek = snapdayofweek
            }
            snapshotdata.snapshotlist = true
            _ = Snapshotlogsandcatalogs(profile: rsyncUIdata.profile,
                                        config: config,
                                        configurations: rsyncUIdata,
                                        snapshotdata: snapshotdata)
        }
    }

    func tagsnapshots() {
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            guard (snapshotdata.getsnapshotdata()?.count ?? 0) > 0 else { return }
            /*
             var snapdayoffweek: String = ""
             var snaplast: String = ""
             plan == 1, only keep last day of week in a month
             plan == 0, keep last day of week every week
             dayofweek
             */
            var localsnaplast = 0
            if snaplast == PlanSnapshots.Last.rawValue {
                localsnaplast = 0 // keep selected day of week every week of month
            } else {
                localsnaplast = 1 // keep last selected day of week pr month
            }
            let tagged = TagSnapshots(plan: localsnaplast,
                                      snapdayoffweek: snapdayofweek,
                                      data: snapshotdata.getsnapshotdata())
            // Market data for delete
            snapshotdata.setsnapshotdata(tagged.logrecordssnapshot)
        }
    }

    func delete() {
        guard confirmdeletesnapshots == true else { return }
        if let config = selectedconfig {
            snapshotdata.delete = DeleteSnapshots(config: config,
                                                  snapshotdata: snapshotdata,
                                                  logrecordssnapshot: snapshotdata.getsnapshotdata())
            snapshotdata.inprogressofdelete = true
            snapshotdata.delete?.deletesnapshots()
        }
    }

    func updateplansnapshot() {
        if var selectedconfig = selectedconfig {
            guard selectedconfig.task == SharedReference.shared.snapshot else { return }
            switch snaplast {
            case PlanSnapshots.Last.rawValue:
                selectedconfig.snaplast = 0
            case PlanSnapshots.Every.rawValue:
                selectedconfig.snaplast = 1
            default:
                return
            }
            selectedconfig.snapdayoffweek = snapdayofweek
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.getallconfigurations())
            updateconfiguration.updateconfiguration(selectedconfig, false)
            reload = true
            updated = true
        }
    }
}

// swiftlint:enable line_length
