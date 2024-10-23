//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//
// swiftlint:disable line_length

import SwiftUI

struct ImportView: View {
    @Binding var focusimport: Bool
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var filenameimport: String = ""
    @State private var configurations = [SynchronizeConfiguration]()
    @State private var isShowingDialog: Bool = false

    let maxhiddenID: Int

    var body: some View {
        VStack {
            if configurations.isEmpty == false {
                ListofTasksLightView(selecteduuids: $selecteduuids, profile: nil, configurations: configurations)
            } else {
                HStack {
                    Text("Select a file for import")
                    OpencatalogView(catalog: $filenameimport, choosecatalog: false)
                }
            }

            Spacer()

            HStack {
                Button("Import tasks") {
                    isShowingDialog = true
                }
                .buttonStyle(ColorfulButtonStyle())
                .confirmationDialog(
                    Text("Import selected or all tasks?"),
                    isPresented: $isShowingDialog
                ) {
                    Button("Import", role: .none) {
                        let updateconfigurations =
                            UpdateConfigurations(profile: rsyncUIdata.profile,
                                                 configurations: rsyncUIdata.configurations)
                        if selecteduuids.isEmpty == true {
                            updateconfigurations.addimportconfigurations(configurations)
                            // Update view
                            for i in 0 ..< configurations.count {
                                rsyncUIdata.configurations?.append(configurations[i])
                            }
                        } else {
                            updateconfigurations.addimportconfigurations(configurations.filter { selecteduuids.contains($0.id) })
                            let importconfigurations = configurations.filter { selecteduuids.contains($0.id) }
                            // Update view
                            for i in 0 ..< importconfigurations.count {
                                rsyncUIdata.configurations?.append(importconfigurations[i])
                            }
                        }
                        focusimport = false
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }

                Button("Dismiss") {
                    focusimport = false
                }
                .buttonStyle(ColorfulButtonStyle())
            }
        }
        .padding()
        .frame(minWidth: 600, minHeight: 500)
        .onChange(of: filenameimport) {
            guard filenameimport.isEmpty == false else { return }
            if let importconfigurations = ReadImportConfigurationsJSON(filenameimport,
                                                                       maxhiddenId: maxhiddenID).importconfigurations
            {
                configurations = importconfigurations
            }
        }
    }
}

// swiftlint:enable line_length
