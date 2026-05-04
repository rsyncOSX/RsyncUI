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
    @State private var snaplast: String = PlanSnapshots.last.rawValue
    @State private var snapdayofweek: String = StringDayofweek.sunday.rawValue
    // Focus buttons from the menu
    @State private var focustagsnapshot: Bool = false
    @State private var focusaborttask: Bool = false
    /// Delete is completed and reload of data
    @State private var deleteiscompleted: Bool = false
    /// Filter
    @State private var filterstring: String = ""
    /// For the weekly or monthly plans
    @State private var isdisabled: Bool = true
    /// confirmationDialog delete logrecords
    @State private var isPresentingConfirm: Bool = false

    var body: some View {
        VStack {
            SnapshotsMainContentView(rsyncUIdata: rsyncUIdata,
                                     snapshotdata: $snapshotdata,
                                     selectedconfig: $selectedconfig,
                                     selectedconfiguuid: $selectedconfiguuid,
                                     filterstring: $filterstring,
                                     deleteiscompleted: $deleteiscompleted,
                                     isdisabled: $isdisabled,
                                     getData: getData)
            if focustagsnapshot == true { labeltagsnapshot }
            if focusaborttask { labelaborttask }

            HStack {
                ConditionalGlassButton(
                    systemImage: "square.and.arrow.down",
                    text: "Update",
                    helpText: "Update plan snapshot"
                ) {
                    updatePlanSnapshot()
                }
                .disabled(isdisabled)

                VStack(alignment: .leading) {
                    pickersnaplast
                        .disabled(isdisabled)

                    pickersnapdayoffweek
                        .disabled(isdisabled)
                }

                if selectedconfiguuid.isEmpty == false {
                    labelnumberoflogs
                }

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
                        Label("Delete unused log records", systemImage: "trash.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color(.blue))
                            .badge(snapshotdata.notmappedloguuids?.count ?? 0)
                    }
                    .help("Delete unused log records")
                    .confirmationDialog(snapshotdata.notmappedloguuids?.count ?? 0 == 1 ? "Delete 1 log" :
                        "Delete \(snapshotdata.notmappedloguuids?.count ?? 0) logs",
                        isPresented: $isPresentingConfirm) {
                            Button("Delete", role: .destructive) {
                                if let uuids = snapshotdata.notmappedloguuids {
                                    Task {
                                        await deleteLogs(uuids)
                                    }
                                }
                            }
                    }
                    .overlay(HStack(alignment: .top) {
                        Image(systemName: String((snapshotdata.notmappedloguuids?.count ?? 0) <= 50
                                ? (snapshotdata.notmappedloguuids?.count ?? 0) : 50))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                    .symbolVariant(.fill)
                    .symbolVariant(.circle)
                    .allowsHitTesting(false)
                    .offset(x: 10, y: -10))
                }
            }

            if selectedconfig?.task == SharedReference.shared.snapshot {
                ToolbarItem {
                    Button {
                        tagSnapshots()
                    } label: {
                        Label("Tag snapshot", systemImage: "tag")
                            .labelStyle(.iconOnly)
                    }
                    .help("Tag snapshot")
                }
            }

            ToolbarItem {
                Button {
                    focusaborttask = true
                } label: {
                    Label("Abort", systemImage: "stop.fill")
                        .labelStyle(.iconOnly)
                }
                .help("Abort (⌘K)")
            }
        })
        .searchable(text: $filterstring)
        .padding()
    }

    var labelnumberoflogs: some View {
        VStack(alignment: .leading) {
            Text(snapshotdata.logrecordssnapshot?.count ?? 0 == 1 ? "There is 1 snapshot" :
                "There are \(snapshotdata.logrecordssnapshot?.count ?? 0) snapshots")
            Text(snapshotdata.snapshotuuidsfordelete.count == 1 ? "Marked 1 snapshot for delete" :
                "Marked \(snapshotdata.snapshotuuidsfordelete.count) snapshots for delete")
        }
    }

    var pickersnapdayoffweek: some View {
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
        Picker("",
               selection: $snaplast) {
            ForEach(PlanSnapshots.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 100)
    }

    var labeltagsnapshot: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focustagsnapshot = false
                tagSnapshots()
            }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }
}

extension SnapshotsView {
    func abort() {
        snapshotdata.setsnapshotdata(nil)
        snapshotdata.delete?.snapshotcatalogstodelete = nil
        // kill any ongoing processes
        InterruptProcess()
    }

    func getData() {
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
                    snaplast = PlanSnapshots.last.rawValue
                } else {
                    snaplast = PlanSnapshots.every.rawValue
                }
            }
            if let snapdayofweek = config.snapdayoffweek {
                self.snapdayofweek = snapdayofweek
            }
            snapshotdata.snapshotlist = true
            Task {
                await loadSnapshotData(for: config)
            }
        }
    }

    @MainActor
    private func loadSnapshotData(for config: SynchronizeConfiguration) async {
        let logrecords = await LogStoreService.loadStore(
            profile: rsyncUIdata.profile,
            configurations: rsyncUIdata.configurations
        )

        _ = Snapshotlogsandcatalogs(
            config: config,
            logrecords: logrecords,
            snapshotdata: snapshotdata
        )
    }

    func tagSnapshots() {
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            guard (snapshotdata.getsnapshotdata()?.count ?? 0) > 0 else { return }
            var localsnaplast = 0
            if snaplast == PlanSnapshots.last.rawValue {
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

    func updatePlanSnapshot() {
        if var selectedconfig {
            guard selectedconfig.task == SharedReference.shared.snapshot else {
                return
            }
            switch snaplast {
            case PlanSnapshots.last.rawValue:
                selectedconfig.snaplast = 0
            case PlanSnapshots.every.rawValue:
                selectedconfig.snaplast = 1
            default:
                selectedconfig.snaplast = 0
            }

            selectedconfig.snapdayoffweek = snapdayofweek
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.configurations)
            Task { @MainActor in
                await updateconfiguration.updateConfiguration(selectedconfig, false)
                rsyncUIdata.configurations = updateconfiguration.configurations
            }
        }
    }

    func deleteLogs(_ uuids: Set<UUID>) async {
        guard let records = snapshotdata.readlogrecordsfromfile else { return }

        _ = await LogStoreService.deleteLogs(
            uuids,
            profile: rsyncUIdata.profile,
            in: records
        )
        snapshotdata.readlogrecordsfromfile = nil
        selectedconfig = nil
        snapshotdata.setsnapshotdata(nil)
        filterstring = ""
        isdisabled = true
    }
}
