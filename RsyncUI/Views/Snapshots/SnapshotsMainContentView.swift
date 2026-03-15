import SwiftUI

struct SnapshotsMainContentView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var snapshotdata: ObservableSnapshotData
    @Binding var selectedconfig: SynchronizeConfiguration?
    @Binding var selectedconfiguuid: Set<SynchronizeConfiguration.ID>
    @Binding var filterstring: String
    @Binding var deleteiscompleted: Bool
    @Binding var isdisabled: Bool

    let getData: () -> Void

    var body: some View {
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
                                    getData()
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
                                getData()
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
                DismissafterMessageView(dismissafter: 2, mytext: "Only rsync version 3.x supports snapshots.")
            }
        }
    }

    private var progressdelete: some View {
        ProgressView("Deleting snapshots",
                     value: Double(snapshotdata.remainingsnapshotstodelete),
                     total: Double(snapshotdata.maxnumbertodelete))
            .frame(width: 200, alignment: .center)
            .onDisappear {
                deleteiscompleted = true
            }
    }
}
