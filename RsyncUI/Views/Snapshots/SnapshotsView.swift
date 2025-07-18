//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import OSLog
import SwiftUI

struct SnapshotsView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State private var snapshotdata = ObservableSnapshotData()
    @State private var selectedconfig: SynchronizeConfiguration?
    @State private var selectedconfiguuid = Set<SynchronizeConfiguration.ID>()
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
    // For the weekly or monthly plans
    @State private var isdisabled: Bool = true
    // confirmationDialog delete logrecords
    @State private var isPresentingConfirm: Bool = false

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ZStack {
                        ConfigurationsTableDataView(selecteduuids: $selectedconfiguuid,
                                                    configurations: rsyncUIdata.configurations)
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
                                        isdisabled = true
                                    }
                                }
                            }

                        if snapshotdata.inprogressofdelete == true { progressdelete }
                    }

                    ZStack {
                        SnapshotListView(snapshotdata: $snapshotdata,
                                         filterstring: $filterstring,
                                         selectedconfig: $selectedconfig)
                            .onChange(of: deleteiscompleted) {
                                if deleteiscompleted == true {
                                    getdata()
                                    deleteiscompleted = false
                                }
                            }
                            .overlay {
                                if snapshotdata.logrecordssnapshot == nil {
                                    ContentUnavailableView {
                                        Label("There are no snapshots", systemImage: "doc.richtext.fill")
                                    } description: {
                                        Text("Please select a snapshot task")
                                    }
                                }
                            }

                        if snapshotdata.snapshotlist { ProgressView() }
                    }
                }

                if SharedReference.shared.rsyncversion3 == false {
                    DismissafterMessageView(dismissafter: 2, mytext: NSLocalizedString("Only rsync version 3.x supports snapshots.", comment: ""))
                }
            }
            if focustagsnapshot == true { labeltagsnapshot }
            if focusaborttask { labelaborttask }

            HStack {
                VStack(alignment: .leading) {
                    pickersnaplast
                        .disabled(isdisabled)

                    pickersnapdayoffweek
                        .disabled(isdisabled)
                }

                labelnumberoflogs

                Spacer()
            }
        }
        .navigationTitle("Snapshot tasks: profile \(rsyncUIdata.profile ?? "Default")")
        .focusedSceneValue(\.tagsnapshot, $focustagsnapshot)
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            if snapshotdata.notmappedloguuids?.count ?? 0 > 0 {
                ToolbarItem {
                    Button {
                        isPresentingConfirm = (snapshotdata.notmappedloguuids?.count ?? 0 > 0)
                    } label: {
                        Image(systemName: "trash.fill")
                            .foregroundColor(Color(.blue))
                            .badge(snapshotdata.notmappedloguuids?.count ?? 0)
                    }
                    .help("Delete not used log records")
                    .confirmationDialog("Delete ^[\(snapshotdata.notmappedloguuids?.count ?? 0) log](inflect: true)",
                                        isPresented: $isPresentingConfirm)
                    {
                        Button("Delete", role: .destructive) {
                            deletelogs(snapshotdata.notmappedloguuids)
                        }
                    }
                    .overlay(HStack(alignment: .top) {
                        Image(systemName: String((snapshotdata.notmappedloguuids?.count ?? 0) <= 50
                                ? (snapshotdata.notmappedloguuids?.count ?? 0) : 50))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    .symbolVariant(.fill)
                    .symbolVariant(.circle)
                    .allowsHitTesting(false)
                    .offset(x: 10, y: -10)
                    )
                }
            }

            if selectedconfig?.task == SharedReference.shared.snapshot {
                ToolbarItem {
                    Button {
                        updateplansnapshot()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(.blue))
                    }
                    .help("Update plan snapshot")
                    .disabled(isdisabled)
                }

                ToolbarItem {
                    Button {
                        tagsnapshots()
                    } label: {
                        Image(systemName: "tag")
                    }
                    .help("Tag snapshot")
                }
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
    var validhiddenIDs: Set<Int> {
        var temp = Set<Int>()
        if let configurations = rsyncUIdata.configurations {
            _ = configurations.map { record in
                temp.insert(record.hiddenID)
            }
        }
        return temp
    }

    func abort() {
        snapshotdata.setsnapshotdata(nil)
        snapshotdata.delete?.snapshotcatalogstodelete = nil
        // kill any ongoing processes
        InterruptProcess()
    }

    func getdata() {
        snapshotdata.snapshotuuidsfordelete.removeAll()
        guard SharedReference.shared.process == nil else { return }
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else {
                isdisabled = true
                snapshotdata.logrecordssnapshot = nil
                return
            }
            isdisabled = false
            // Setting values for tagging snapshots
            if let mysnaplast = config.snaplast {
                if mysnaplast == 0 {
                    snaplast = PlanSnapshots.Last.rawValue
                } else {
                    snaplast = PlanSnapshots.Every.rawValue
                }
            }
            if let snapdayofweek = config.snapdayoffweek {
                self.snapdayofweek = snapdayofweek
            }
            snapshotdata.snapshotlist = true

            if let config = selectedconfig {
                Task {
                    let logrecords = await
                        ActorReadLogRecordsJSON().readjsonfilelogrecords(rsyncUIdata.profile, validhiddenIDs)
                    _ = Snapshotlogsandcatalogs(config: config,
                                                logrecords: logrecords ?? [],
                                                snapshotdata: snapshotdata)
                }
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
            guard selectedconfig.task == SharedReference.shared.snapshot else {
                return
            }
            switch snaplast {
            case PlanSnapshots.Last.rawValue:
                selectedconfig.snaplast = 0
            case PlanSnapshots.Every.rawValue:
                selectedconfig.snaplast = 1
            default:
                selectedconfig.snaplast = 0
            }

            selectedconfig.snapdayoffweek = snapdayofweek
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.configurations)
            updateconfiguration.updateconfiguration(selectedconfig, false)
            rsyncUIdata.configurations = updateconfiguration.configurations
            updated = true
            if selectedconfig.snaplast == 1 {
                Logger.process.info("SnapshotsView: saved EVERY day in month for \(snapdayofweek, privacy: .public)")
            } else {
                Logger.process.info("SnapshotsView: saved LAST day in month for \(snapdayofweek, privacy: .public)")
            }
        }
        Task {
            try await Task.sleep(seconds: 2)
        }
    }

    func deletelogs(_ uuids: Set<UUID>?) {
        if var records = snapshotdata.readlogrecordsfromfile, let uuids {
            var indexset = IndexSet()
            for i in 0 ..< records.count {
                for j in 0 ..< uuids.count {
                    if let index = records[i].logrecords?.firstIndex(
                        where: { $0.id == uuids[uuids.index(uuids.startIndex, offsetBy: j)] })
                    {
                        indexset.insert(index)
                    }
                }
                records[i].logrecords?.remove(atOffsets: indexset)
                indexset.removeAll()
            }
            WriteLogRecordsJSON(rsyncUIdata.profile, records)
            snapshotdata.readlogrecordsfromfile = nil
            selectedconfig = nil
            snapshotdata.setsnapshotdata(nil)
            filterstring = ""
            isdisabled = true
        }
    }
}
