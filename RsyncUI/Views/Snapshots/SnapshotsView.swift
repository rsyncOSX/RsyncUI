//
//  SnapshotsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 23/02/2021.
//

import SwiftUI

struct SnapshotsView: View {
    @EnvironmentObject var rsyncOSXData: RsyncOSXdata
    @EnvironmentObject var errorhandling: ErrorHandling

    @StateObject var snapshotdata = SnapshotData()

    @Binding var selectedconfig: Configuration?
    @State private var snapshotrecords: Logrecordsschedules?
    @State private var selecteduuids = Set<UUID>()

    // Not used but requiered in parameter
    @State private var inwork = -1
    @State private var selectable = false

    var body: some View {
        ConfigurationsList(selectedconfig: $selectedconfig.onChange { getdata() },
                           selecteduuids: $selecteduuids,
                           inwork: $inwork,
                           selectable: $selectable)

        Spacer()

        SnapshotListView(selectedconfig: $selectedconfig,
                         snapshotrecords: $snapshotrecords,
                         selecteduuids: $selecteduuids)
            .environmentObject(snapshotdata)
            .onDeleteCommand(perform: { delete() })

        if snapshotdata.state == .getdata { ImageZstackProgressview() }

        HStack {
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
        .alert(isPresented: errorhandling.isPresentingAlert, content: {
            Alert(localizedError: errorhandling.activeError!)

        })
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
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            _ = Snapshotlogsandcatalogs(config: config,
                                        configurationsSwiftUI: rsyncOSXData.rsyncdata?.configurationData,
                                        schedulesSwiftUI: rsyncOSXData.rsyncdata?.scheduleData,
                                        snapshotdata: snapshotdata)
        }
    }

    func tagsnapshots() {
        if let config = selectedconfig {
            guard config.task == SharedReference.shared.snapshot else { return }
            guard snapshotdata.getsnapshotdata().count > 0 else { return }
            let tagged = TagSnapshots(plan: config.snaplast ?? 0,
                                      snapdayoffweek: config.snapdayoffweek ?? "",
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

    // TODO:
    func delete() {
        // Send all selected UUIDs to mark for delete
        _ = NotYetImplemented()
    }
}
