//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var snapshotdata = SnapshotData()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()
    // If not a snapshot
    @State private var notsnapshot = false
    // Plan for tagging and administrating snapshots
    @State private var snaplast: String = PlanSnapshots.Last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.Sunday.rawValue
    // Update plan and snapday
    @State private var updated: Bool = false
    // Focus buttons from the menu
    @State private var focustagsnapshot: Bool = false
    @State private var focusaborttask: Bool = false
    // Delete is completed and reload of data
    @State private var deleteiscompleted: Bool = false
    // Filter
    @State private var filterstring: String = ""

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ZStack {
                        ListofTasksLightView(selecteduuids: $selectedconfiguuid,
                                             profile: rsyncUIdata.profile,
                                             configurations: rsyncUIdata.configurations ?? [])
                            .onChange(of: selectedconfiguuid) {
                                guard SharedReference.shared.rsyncversion3 == true else { return }
                                if let configurations = rsyncUIdata.configurations {
                                    if let index = configurations.firstIndex(where: { $0.id == selectedconfiguuid.first }) {
                                        selectedconfig = configurations[index]
                                        getdata()
                                    } else {
                                        selectedconfig = nil
                                        snapshotdata.setsnapshotdata(nil)
                                        filterstring = ""
                                    }
                                }
                            }

                        if snapshotdata.inprogressofdelete == true { progressdelete }
                        if snapshotdata.snapshotlist { ProgressView() }
                    }

                    SnapshotListView(snapshotdata: $snapshotdata,
                                     filterstring: $filterstring,
                                     selectedconfig: $selectedconfig)
                        .onChange(of: deleteiscompleted) {
                            if deleteiscompleted == true {
                                getdata()
                                deleteiscompleted = false
                            }
                        }
                }

                if notsnapshot == true { MessageView(dismissafter: 2, mytext: NSLocalizedString("Not a snapshot task.", comment: ""), width: 200) }

                if SharedReference.shared.rsyncversion3 == false, notsnapshot == false {
                    MessageView(dismissafter: 2, mytext: NSLocalizedString("Only rsync version 3.x supports snapshots.", comment: ""), width: 450)
                }
            }
            if focustagsnapshot == true { labeltagsnapshot }
            if focusaborttask { labelaborttask }

            HStack {
                VStack(alignment: .leading) {
                    pickersnaplast

                    pickersnapdayoffweek
                }

                labelnumberoflogs
                
                

                Spacer()
            }
        }
        .focusedSceneValue(\.tagsnapshot, $focustagsnapshot)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    updateplansnapshot()
                } label: {
                    Image(systemName: "return")
                }
                .help("Update plan snapshot")
            }

            ToolbarItem {
                Button {
                    tagsnapshots()
                } label: {
                    Image(systemName: "tag")
                }
                .help("Tag snapshot")
            }

            ToolbarItem {
                Button {
                    focusaborttask = true
                } label: {
                    Image(systemName: "stop.fill")
                }
                .help("Abort (⌘K)")
            }
        })
        .searchable(text: $filterstring)
        .padding()
    }

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text("There is ^[\(snapshotdata.logrecordssnapshot?.count ?? 0) snapshot](inflect: true)")
            Text("Marked ^[\(snapshotdata.snapshotuuidsfordelete.count) snapshot](inflect: true) for delete")
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

    var progressdelete: some View {
        ProgressView("Deleting snapshots",
                     value: Double(snapshotdata.remainingsnapshotstodelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .frame(width: 200, alignment: .center)
            .onDisappear(perform: {
                deleteiscompleted = true
            })
    }
}

extension SnapshotsView {
    func abort() {
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
                Task {
                    try await Task.sleep(seconds: 1)
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
            var profile: String? = rsyncUIdata.profile ?? ""
            if profile == SharedReference.shared.defaultprofile || profile == nil {
                profile = nil
            }
            var validhiddenIDs = Set<Int>()
            if let configurations = rsyncUIdata.configurations {
                for i in 0 ..< configurations.count {
                    validhiddenIDs.insert(configurations[i].hiddenID)
                }
            }
            if let config = selectedconfig,
               let logrecords = ReadLogRecordsJSON(profile, validhiddenIDs).logrecords
            {
                _ = Snapshotlogsandcatalogs(config: config,
                                            logrecords: logrecords,
                                            snapshotdata: snapshotdata)
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

    func updateplansnapshot() {
        if var selectedconfig {
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
                                     configurations: rsyncUIdata.configurations)
            updateconfiguration.updateconfiguration(selectedconfig, false)
            updated = true
        }
    }
}
