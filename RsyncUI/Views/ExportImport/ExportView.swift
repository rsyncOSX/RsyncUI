//
//  ExportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI

struct ExportView: View {
    @Binding var focusexport: Bool
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State var exportcatalog: String = Homepath().userHomeDirectoryPath ?? ""
    @State var filenameexport: String = "export"

    @State var somesnapshottask: Bool = false

    let configurations: [SynchronizeConfiguration]
    let profile: String?
    let preselectedtasks: Set<SynchronizeConfiguration.ID>

    var body: some View {
        VStack {
            ListofTasksLightView(selecteduuids: $selecteduuids, profile: profile, configurations: configurations)
                .onChange(of: selecteduuids) {
                    let snapshottasks = configurations.filter { $0.task == SharedReference.shared.snapshot }
                    if snapshottasks.count > 0 {
                        somesnapshottask = true
                    }
                }

            if somesnapshottask {
                MessageView(dismissafter: 2, mytext: "Some tasks are snapshots, cannot be exported")
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

                OpencatalogView(catalog: $exportcatalog, choosecatalog: true)

                Button("Export") {
                    var path = ""
                    if exportcatalog.hasSuffix("/") == true {
                        path = exportcatalog + filenameexport + ".json"
                    } else {
                        path = exportcatalog + "/" + filenameexport + ".json"
                    }
                    guard exportcatalog.isEmpty == false, filenameexport.isEmpty == false else {
                        focusexport = false
                        return
                    }
                    _ = WriteExportConfigurationsJSON(path, selectedconfigurations())
                    focusexport = false
                }
                .help("Export tasks")
                .buttonStyle(ColorfulButtonStyle())

                Spacer()

                Button("Dismiss") {
                    focusexport = false
                }
                .buttonStyle(ColorfulButtonStyle())
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
        EditValue(150, NSLocalizedString("Filename export", comment: ""),
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
