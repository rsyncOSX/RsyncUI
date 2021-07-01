//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct SnapshotsView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @StateObject var snapshotdata = SnapshotData()

    @Binding var selectedconfig: Configuration?
    @Binding var reload: Bool

    @State private var snapshotrecords: Logrecordsschedules?
    @State private var selecteduuids = Set<UUID>()
    // Not used but requiered in parameter
    @State private var inwork = -1
    // If not a snapshot
    @State private var notsnapshot = false
    // Cannot collect remote cataloglist for more than one task a time
    @State private var gettingdata = false
    // Plan for tagging and administrating snapshots
    @State private var snaplast: String = PlanSnapshots.Last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.Sunday.rawValue
    // Update plan and snapday
    @State private var updated: Bool = false
    // Confirm delete
    @State private var confirmdeletesnapshots = false
    // Alert for delete
    @State private var showAlertfordelete = false
    @State private var searchText: String = ""

    let selectable = false

    var body: some View {
        ZStack {
            ConfigurationsList(selectedconfig: $selectedconfig.onChange { getdata() },
                               selecteduuids: $selecteduuids,
                               inwork: $inwork,
                               searchText: $searchText,
                               selectable: selectable)

            if notsnapshot == true { notasnapshottask }
            if gettingdata == true { gettingdatainprocess }
            if updated == true { notifyupdated }
        }

        Spacer()

        SnapshotListView(selectedconfig: $selectedconfig,
                         snapshotrecords: $snapshotrecords,
                         selecteduuids: $selecteduuids)
            .environmentObject(snapshotdata)
            .onDeleteCommand(perform: { delete() })

        if snapshotdata.state == .getdata { RotatingDotsIndicatorView()
            .frame(width: 50.0, height: 50.0)
            .foregroundColor(.red)
        }

        HStack {
            Button("Save") { updateplansnapshot() }
                .buttonStyle(PrimaryButtonStyle())

            VStack(alignment: .leading) {
                pickersnaplast

                pickersnapdayoffweek
            }

            labelnumberoflogs

            Spacer()

            if snapshotdata.inprogressofdelete == true { progressdelete }

            Spacer()

            Group {
                Button("Tag") { tagsnapshots() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Select") { select() }
                    .buttonStyle(PrimaryButtonStyle())

                Button("Delete") { showAlertfordelete = true }
                    .sheet(isPresented: $showAlertfordelete) {
                        ConfirmDeleteSnapshots(isPresented: $showAlertfordelete,
                                               delete: $confirmdeletesnapshots,
                                               uuidstodelete: $snapshotdata.uuidsfordelete)
                            .onDisappear {
                                delete()
                            }
                    }
                    .buttonStyle(AbortButtonStyle())

                Button("Abort") { abort() }
                    .buttonStyle(AbortButtonStyle())
            }
        }
    }

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text(NSLocalizedString("Number of logrecords", comment: "") +
                ": " + "\(snapshotdata.logrecordssnapshot?.count ?? 0)")
            Text(NSLocalizedString("Number to delete", comment: "") +
                ": " + "\(snapshotdata.uuidsfordelete?.count ?? 0)")
        }
    }

    var notasnapshottask: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional(NSLocalizedString("Not a snapshot task", comment: "")), subTitle: Optional(""))
    }

    var gettingdatainprocess: some View {
        AlertToast(type: .error(Color.red),
                   title: Optional(NSLocalizedString("In process in getting data", comment: "")), subTitle: Optional(""))
    }

    var pickersnapdayoffweek: some View {
        // Picker("Day of week" + ":",
        Picker("",
               selection: $snapdayofweek) {
            ForEach(StringDayofweek.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var pickersnaplast: some View {
        // Picker("Plan" + ":",
        Picker("",
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
                   title: Optional(NSLocalizedString("Updated", comment: "")),
                   subTitle: Optional(""))
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    updated = false
                }
            })
    }

    var progressdelete: some View {
        ProgressView("",
                     value: Double(snapshotdata.progressindelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .progressViewStyle(GaugeProgressStyle())
            .frame(width: 50.0, height: 50.0)
            .contentShape(Rectangle())
            .onDisappear(perform: {
                getdata()
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
        snapshotdata.uuidsfordelete?.removeAll()
        snapshotdata.uuidsfromlogrecords?.removeAll()
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
                                        configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                        schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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
            var localsnaplast: Int = 0
            if snaplast == PlanSnapshots.Last.rawValue {
                localsnaplast = 0 // keep selected day of week every week of month
            } else {
                localsnaplast = 1 // keep last selected day of week pr month
            }
            let tagged = TagSnapshots(plan: localsnaplast,
                                      snapdayoffweek: snapdayofweek,
                                      data: snapshotdata.getsnapshotdata())
            selecteduuids = tagged.selecteduuids
            snapshotdata.setsnapshotdata(tagged.logrecordssnapshot)
            snapshotdata.uuidsfordelete = tagged.selecteduuids
        }
    }

    func select() {
        // Also prepare logs for delete if not tagged
        if snapshotdata.uuidsfordelete == nil {
            snapshotdata.uuidsfordelete = Set<UUID>()
        }
        if let log = snapshotrecords {
            if selecteduuids.contains(log.id) {
                snapshotdata.uuidsfordelete?.remove(log.id)
                selecteduuids.remove(log.id)
            } else {
                snapshotdata.uuidsfordelete?.insert(log.id)
                selecteduuids.insert(log.id)
            }
        }
    }

    func delete() {
        guard confirmdeletesnapshots == true else { return }
        if let config = selectedconfig {
            snapshotdata.delete = DeleteSnapshots(config: config,
                                                  configurationsSwiftUI: rsyncUIdata.rsyncdata?.configurationData,
                                                  schedulesSwiftUI: rsyncUIdata.rsyncdata?.scheduleData,
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
                UpdateConfigurations(profile: rsyncUIdata.rsyncdata?.profile,
                                     configurations: rsyncUIdata.rsyncdata?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(selectedconfig, false)
            reload = true
            updated = true
        }
    }

    func deletelogs() {}
}
