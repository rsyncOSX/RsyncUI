//
//  ExportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var activeSheet: SheetType?
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State var exportcatalog: String = Homepath().userHomeDirectoryPath ?? ""
    @State var filenameexport: String = "export"

    @State var somesnapshottask: Bool = false

    let configurations: [SynchronizeConfiguration]
    let preselectedtasks: Set<SynchronizeConfiguration.ID>

    var body: some View {
        VStack {
            ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                        configurations: configurations)
                .onChange(of: selecteduuids) {
                    let snapshottasks = configurations.filter { $0.task == SharedReference.shared.snapshot }
                    if snapshottasks.count > 0 {
                        somesnapshottask = true
                    }
                }

            if somesnapshottask {
                DismissafterMessageView(dismissafter: 2, mytext: "Some tasks are snapshots, cannot be exported")
                    .onDisappear {
                        somesnapshottask = false
                    }
            }

            HStack {
                if exportcatalog.hasSuffix("/") {
                    Text(exportcatalog)
                        .foregroundColor(.secondary)
                } else {
                    Text(exportcatalog + "/")
                        .foregroundColor(.secondary)
                }

                setfilename

                Text(".json")
                    .foregroundColor(.secondary)

                OpencatalogView(selecteditem: $exportcatalog, catalogs: true)

                Button("Export") {
                    var path = ""
                    if exportcatalog.hasSuffix("/") == true {
                        path = exportcatalog + filenameexport + ".json"
                    } else {
                        path = exportcatalog + "/" + filenameexport + ".json"
                    }
                    guard exportcatalog.isEmpty == false, filenameexport.isEmpty == false else {
                        activeSheet = nil
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, selectedconfigurations())
                    activeSheet = nil
                }
                .help("Export tasks")
                .buttonStyle(ColorfulButtonStyle())

                Spacer()
                
                if #available(macOS 26.0, *) {
                    
                    Button("Close", role: .close) {
                        activeSheet = nil
                        dismiss()
                    }
                } else {
                    
                    Button("Close") {
                        activeSheet = nil
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            if FileManager.default.locationExists(at: exportcatalog + "/" + "tmp", kind: .folder) {
                exportcatalog += "/" + "tmp" + "/"
            } else {
                exportcatalog += "/"
            }
            let snapshottasks = configurations.filter { $0.task == SharedReference.shared.snapshot }
            if snapshottasks.count > 0 {
                somesnapshottask = true
            }
            if preselectedtasks.count > 0 {
                selecteduuids.removeAll()
                selecteduuids = preselectedtasks
            }
        }
    }

    var setfilename: some View {
        EditValueScheme(150, NSLocalizedString("Filename export", comment: ""),
                        $filenameexport)
            .textContentType(.none)
    }

    func selectedconfigurations() -> [SynchronizeConfiguration] {
        if selecteduuids.count > 0 {
            configurations.filter { selecteduuids.contains($0.id) && $0.task != SharedReference.shared.snapshot }
        } else {
            configurations.filter { $0.task != SharedReference.shared.snapshot }
        }
    }
}
