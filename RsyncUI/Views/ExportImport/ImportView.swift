//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//
// swiftlint:disable line_length

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) var dismiss

    @Binding var focusimport: Bool
    @Bindable var rsyncUIdata: RsyncUIconfigurations

    @State var selecteduuids = Set<SynchronizeConfiguration.ID>()
    @State private var filenameimport: String = ""
    @State private var configurations = [SynchronizeConfiguration]()
    @State private var isShowingDialog: Bool = false
    @State private var showimportdialog: Bool = false

    let maxhiddenID: Int

    var body: some View {
        VStack {
            if configurations.isEmpty == false {
                VStack {
                    ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                configurations: configurations)

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
                                    rsyncUIdata.configurations = updateconfigurations.addimportconfigurations(configurations)
                                } else {
                                    rsyncUIdata.configurations = updateconfigurations.addimportconfigurations(configurations.filter { selecteduuids.contains($0.id) })
                                }
                                if SharedReference.shared.duplicatecheck {
                                    if let configurations = rsyncUIdata.configurations {
                                        VerifyDuplicates(configurations)
                                    }
                                }
                                focusimport = false
                                dismiss()
                            }
                            .buttonStyle(ColorfulButtonStyle())
                        }

                        Button("Dismiss") {
                            focusimport = false
                        }
                        .buttonStyle(ColorfulButtonStyle())
                    }
                }
                .frame(minWidth: 600, minHeight: 500)

            } else {
                HStack {
                    Button("Select a file for import") {
                        showimportdialog = true
                    }
                    .buttonStyle(ColorfulButtonStyle())
                    .fileImporter(isPresented: $showimportdialog,
                                  allowedContentTypes: [uutype],
                                  onCompletion: { result in
                                      switch result {
                                      case let .success(url):
                                          filenameimport = url.relativePath
                                          guard filenameimport.isEmpty == false else { return }
                                          if let importconfigurations = ReadImportConfigurationsJSON(filenameimport,
                                                                                                     maxhiddenId: maxhiddenID).importconfigurations
                                          {
                                              configurations = importconfigurations
                                          }
                                      case let .failure(error):
                                          SharedReference.shared.errorobject?.alert(error: error)
                                      }
                                  })

                    Button("Dismiss") {
                        focusimport = false
                        dismiss()
                    }
                    .buttonStyle(ColorfulButtonStyle())
                }
            }
        }
        .padding()
    }

    var uutype: UTType {
        .item
    }
}

// swiftlint:enable line_length
