import SwiftUI

struct RestoreContentView: View {
    @Binding var restore: ObservableRestore
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>
    @Binding var snapshotdata: ObservableSnapshotData
    @Binding var filterstring: String
    @Binding var gettingfilelist: Bool
    @Binding var profile: String?

    let configurations: [SynchronizeConfiguration]
    let getSnapshotLogsAndCatalogs: () -> Void

    var body: some View {
        VStack {
            ZStack {
                HStack {
                    ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                configurations: configurations)
                        .onChange(of: selecteduuids) {
                            if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                restore.selectedconfig = configurations[index]
                                if configurations[index].task == SharedReference.shared.snapshot {
                                    getSnapshotLogsAndCatalogs()
                                }
                                restore.restorefilelist.removeAll()
                            } else {
                                restore.selectedconfig = nil
                                restore.filestorestore = ""
                                restore.restorefilelist.removeAll()
                                snapshotdata.snapshotfolders.removeAll()
                                filterstring = ""
                            }
                        }
                        .overlay {
                            if configurations.count == 0 {
                                ContentUnavailableView {
                                    Label("No tasks yet", systemImage: "doc.richtext.fill")
                                } description: {
                                    Text("And nothing to restore")
                                }
                            }
                        }

                    VStack(alignment: .leading) {
                        RestoreFilesTableView(filestorestore: $restore.filestorestore,
                                              datalist: restore.restorefilelist)
                            .onChange(of: profile) {
                                restore.restorefilelist.removeAll()
                            }
                            .overlay {
                                if filterstring.count > 0,
                                   restore.restorefilelist.count == 0 {
                                    ContentUnavailableView.search
                                }
                            }

                        Spacer()
                    }
                }

                if gettingfilelist { ProgressView() }
                if restore.restorefilesinprogress {
                    SynchronizeProgressView(
                        max: restore.max,
                        progress: restore.progress,
                        statusText: "Restoring..."
                    )
                }

                if restore.selectedconfig?.offsiteServer.isEmpty == true {
                    DismissafterMessageView(dismissafter: 2, mytext: "Use macOS Finder to restore files from attached discs.")
                }
            }
        }
    }
}
