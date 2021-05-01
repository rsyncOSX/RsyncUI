//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotsView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var snapshotdata = SnapshotData()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var logs: Bool

    // Discrapency
    @State var uuids: Set<UUID>?
    @State private var snapshotrecords: Logrecordsschedules?
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false
    // If not a snapshot
    @State private var notsnapshot = false
    // Cannot collect remote cataloglist for more than one task a time
    @State private var gettingdata = false
    // Plan for tagging and administrating snapshots
    @State private var snaplast: String = PlanSnapshots.Last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.Sunday.rawValue

    var body: some View {
        VStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { getdata() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            Spacer()

            ZStack {
                SnapshotListView(selectedconfig: $selectedconfig,
                                 snapshotrecords: $snapshotrecords,
                                 selecteduuids: $selecteduuids)
                    .environmentObject(snapshotdata)
                    .onDeleteCommand(perform: { delete() })

                if snapshotdata.state == .getdata { RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
                }
            }
        }

        if notsnapshot == true { notasnapshottask }
        if gettingdata == true { gettingdatainprocess }
        // Number of local logrecords or remote catalogs does not
        // match, there is either to many logrecords or missing logrecords
        // for remote snapshotcatalogs
        // The match is important for adminsitrating snapshots
        if snapshotdata.numlocallogrecords != snapshotdata.numremotecatalogs {
            HStack {
                discrepancy

                Button(NSLocalizedString("Discrepancy", comment: "Tag")) {
                    if let config = selectedconfig {
                        rsyncUIData.filterbyhiddenIDanduuids(config.hiddenID, uuids)
                    }
                    logs = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }

        HStack {
            VStack(alignment: .leading) {
                pickersnaplast

                pickersnapdayoffweek
            }

            Text(labelnumberoflogs)

            Spacer()

            Button(NSLocalizedString("Tag", comment: "Tag")) { tagsnapshots() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Select", comment: "Select button")) { select() }
                .buttonStyle(PrimaryButtonStyle())

            Button(NSLocalizedString("Delete", comment: "Delete")) { delete() }
                .buttonStyle(AbortButtonStyle())

            Button(NSLocalizedString("Abort", comment: "Abort button")) { abort() }
                .buttonStyle(AbortButtonStyle())
        }
    }

    var labelnumberoflogs: String {
        NSLocalizedString("Number of logs", comment: "") + ": " + "\(snapshotdata.numremotecatalogs)"
    }

    var notasnapshottask: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Not a snapshot task", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var gettingdatainprocess: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("In process in getting data", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var discrepancy: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("some discrepancy", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 200, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
    }

    var pickersnapdayoffweek: some View {
        // Picker(NSLocalizedString("Day of week", comment: "SnapshotsView") + ":",
        Picker(NSLocalizedString("", comment: "SnapshotsView"),
               selection: $snapdayofweek) {
            ForEach(StringDayofweek.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var pickersnaplast: some View {
        // Picker(NSLocalizedString("Plan", comment: "SnapshotsView") + ":",
        Picker(NSLocalizedString("", comment: "SnapshotsView"),
               selection: $snaplast) {
            ForEach(PlanSnapshots.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }
}

extension SnapshotsView {
    func abort() {
        snapshotdata.state = .start
        snapshotdata.setsnapshotdata(nil)
        // kill any ongoing processes
        _ = InterruptProcess()
    }

    func getdata() {
        guard SharedReference.shared.process == nil else {
            gettingdata = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                gettingdata = false
            }
            return
        }
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
            if rsyncUIData.profile != "test" {
                var snapshotslogsandcatalogs: Snapshotlogsandcatalogs?
                    = Snapshotlogsandcatalogs(config: config,
                                              configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                              schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                              snapshotdata: snapshotdata,
                                              test: false)
                uuids = snapshotslogsandcatalogs?.uuids
                // Release object
                snapshotslogsandcatalogs = nil

            } else {
                var snapshotslogsandcatalogs: Snapshotlogsandcatalogs?
                    = Snapshotlogsandcatalogs(config: config,
                                              configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                              schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                              snapshotdata: snapshotdata,
                                              test: true)
                uuids = snapshotslogsandcatalogs?.uuids
                // Release object
                snapshotslogsandcatalogs = nil
            }
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
            var localsnaplast: Int = 0
            if snaplast == PlanSnapshots.Last.rawValue {
                localsnaplast = 0 // keep selected day of week every week of month
            } else {
                localsnaplast = 1 // keep last selected day of week pr month
            }
            let tagged = TagSnapshots(plan: localsnaplast,
                                      snapdayoffweek: snapdayofweek,
                                      data: snapshotdata.getsnapshotdata())
            snapshotdata.setsnapshotdata(tagged.logrecordssnapshot)
        }
    }

    func select() {
        if let log = snapshotrecords {
            if selecteduuids.contains(log.id) {
                selecteduuids.remove(log.id)
            } else {
                selecteduuids.insert(log.id)
            }
        }
    }

    func delete() {
        // Send all selected UUIDs to mark for delete
        _ = NotYetImplemented()
    }
}

/*
 TODO:
 - function for delete
 - there is a bug in collecting many snapshot logs, a mixup of snapshotnums and logs
 - add plan for snapshots week or monthly
 - REMOVE test when done
 */
