//
//  ImportView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/07/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var activeSheet: SheetType?

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
                        if #available(macOS 26.0, *) {
                            Button("Import tasks") {
                                isShowingDialog = true
                            }
                            .buttonStyle(RefinedGlassButtonStyle())
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
                                    activeSheet = nil
                                }
                                .buttonStyle(RefinedGlassButtonStyle())
                            }

                        } else {
                            Button("Import tasks") {
                                isShowingDialog = true
                            }
                            .buttonStyle(.borderedProminent)
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
                                    activeSheet = nil
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        // Because of the role .destructive keep the if #available(macOS 26.0, *)
                        if #available(macOS 26.0, *) {
                            Button("Close", role: .close) {
                                activeSheet = nil
                                dismiss()
                            }
                            .buttonStyle(RefinedGlassButtonStyle())

                        } else {
                            Button("Close") {
                                activeSheet = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .frame(minWidth: 600, minHeight: 500)

            } else {
                HStack {
                    ConditionalGlassButton(
                        systemImage: "",
                        text: "Import file",
                        helpText: "Import file"
                    ) {
                        showimportdialog = true
                    }
                    .fileImporter(isPresented: $showimportdialog,
                                  allowedContentTypes: [uutype],
                                  onCompletion: { result in
                                      switch result {
                                      case let .success(url):
                                          filenameimport = url.relativePath
                                          guard filenameimport.isEmpty == false else { return }
                                          if let importconfigurations = ReadImportConfigurationsJSON(filenameimport,
                                                                                                     maxhiddenId: maxhiddenID).importconfigurations {
                                              configurations = importconfigurations
                                          }
                                      case let .failure(error):
                                          SharedReference.shared.errorobject?.alert(error: error)
                                      }
                                  })

                    // Because of the role .destructive keep the if #available(macOS 26.0, *)
                    if #available(macOS 26.0, *) {
                        Button("Close", role: .close) {
                            activeSheet = nil
                            dismiss()
                        }
                        .buttonStyle(RefinedGlassButtonStyle())

                    } else {
                        Button("Close") {
                            activeSheet = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
    }

    var uutype: UTType {
        .item
    }
}
