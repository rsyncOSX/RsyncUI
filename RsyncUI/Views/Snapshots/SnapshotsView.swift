//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct SnapshotsView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var snapshotdata = SnapshotData()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool
    @Binding var logs: Bool

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
    // AlertToast
    @State private var showAlert: Bool = false
    // Not yet completed
    @State private var notyetcompleted: Bool = false
    // Update plan and snapday
    @State private var updated: Bool = false
    // Expand tagged
    @State private var expand: Bool = false

    var body: some View {
        if expand == false {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { getdata() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               selectable: $selectable)

            Spacer()
        }

        ZStack {
            HStack {
                Button(action: {
                    let previous = expand
                    expand = !previous
                }) {
                    if expand {
                        Image(systemName: "minus")
                    } else {
                        Image(systemName: "plus")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())

                SnapshotListView(selectedconfig: $selectedconfig,
                                 snapshotrecords: $snapshotrecords,
                                 selecteduuids: $selecteduuids)
                    .environmentObject(snapshotdata)
                    .onDeleteCommand(perform: { delete() })
            }

            if snapshotdata.state == .getdata { RotatingDotsIndicatorView()
                .frame(width: 50.0, height: 50.0)
                .foregroundColor(.red)
            }

            if notsnapshot == true { notasnapshottask }
            if gettingdata == true { gettingdatainprocess }
            if snapshotdata.numlocallogrecords != snapshotdata.numremotecatalogs { discrepancy }
            if updated == true { notifyupdated }
            if notyetcompleted == true { messagenotyetcompleted }
        }

        HStack {
            Button(NSLocalizedString("Save", comment: "Tag")) { updateplansnapshot() }
                .buttonStyle(PrimaryButtonStyle())

            VStack(alignment: .leading) {
                pickersnaplast

                pickersnapdayoffweek
            }

            labelnumberoflogs

            // If there is some discrepancy
            if snapshotdata.numlocallogrecords != snapshotdata.numremotecatalogs {
                Button(NSLocalizedString("Discrepancy", comment: "Tag")) {
                    rsyncUIData.filterbyUUIDs(snapshotdata.uuidsLog)
                    logs = true
                }
                .buttonStyle(PrimaryButtonStyle())
            }

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

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Number of aligned snapshotcatalogs", comment: "") +
                ": " + "\(snapshotdata.numremotecatalogs)")
            Text(NSLocalizedString("Number of logrecords", comment: "") +
                ": " + "\(snapshotdata.numlocallogrecords)")
        }
    }

    var notasnapshottask: some View {
        AlertToast(type: .error(Color.red), title: Optional(NSLocalizedString("Not a snapshot task", comment: "settings")), subTitle: Optional(""))
    }

    var gettingdatainprocess: some View {
        AlertToast(type: .error(Color.red), title: Optional(NSLocalizedString("In process in getting data", comment: "settings")), subTitle: Optional(""))
    }

    var discrepancy: some View {
        AlertToast(type: .error(Color.red), title: Optional(NSLocalizedString("some discrepancy", comment: "settings")), subTitle: Optional(""))
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

    var notifyupdated: some View {
        AlertToast(type: .complete(Color.green),
                   title: Optional(NSLocalizedString("Updated",
                                                     comment: "settings")),
                   subTitle: Optional(""))
            .onAppear(perform: {
                // Show updated for 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    updated = false
                }
            })
    }

    var messagenotyetcompleted: some View {
        AlertToast(type: .regular, title: Optional("Sorry, this function is not yet completed"),
                   subTitle: Optional("... I am working on it ..."))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    notyetcompleted = false
                }
            })
    }
}

extension SnapshotsView {
    func abort() {
        snapshotdata.state = .start
        snapshotdata.setsnapshotdata(nil)
        // Close the Discrepancy alert
        snapshotdata.numlocallogrecords = 0
        snapshotdata.numremotecatalogs = 0
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
            _ = Snapshotlogsandcatalogs(config: config,
                                        configurationsSwiftUI: rsyncUIData.rsyncdata?.configurationData,
                                        schedulesSwiftUI: rsyncUIData.rsyncdata?.scheduleData,
                                        snapshotdata: snapshotdata)
        }
    }

    func tagsnapshots() {
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            guard (snapshotdata.getsnapshotdata()?.count ?? 0) > 0 else { return }
            // Reset the Discrapancy if true
            if snapshotdata.numlocallogrecords != snapshotdata.numremotecatalogs {
                snapshotdata.numlocallogrecords = 0
                snapshotdata.numremotecatalogs = 0
            }
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
        notyetcompleted = true
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
                UpdateConfigurations(profile: rsyncUIData.rsyncdata?.profile,
                                     configurations: rsyncUIData.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(selectedconfig, false)
            reload = true
            updated = true
        }
    }
}
