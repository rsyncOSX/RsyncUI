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
                        AdaptiveProminentButton(
                            systemImage: "",
                            text: "Import tasks",
                            helpText: "Import tasks"
                        ) {
                            isShowingDialog = true
                        }
                        .confirmationDialog(
                            "Import selected or all tasks?",
                            isPresented: $isShowingDialog
                        ) {
                            Button("Import") {
                                Task { @MainActor in
                                    await importSelectedConfigurations()
                                }
                            }
                        }

                        AdaptiveCloseButton(action: close)
                    }
                }
                .frame(minWidth: 600, minHeight: 500)
            } else {
                HStack {
                    AdaptiveProminentButton(
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
                                          Task { @MainActor in
                                              if let importconfigurations = await ReadImportConfigurationsJSON.read(
                                                  filenameimport,
                                                  maxhiddenId: maxhiddenID
                                              ) {
                                                  configurations = importconfigurations
                                              }
                                          }
                                      case let .failure(error):
                                          SharedReference.shared.errorobject?.alert(error: error)
                                      }
                                  })

                    AdaptiveCloseButton(action: close)
                }
            }
        }
        .padding()
    }

    var uutype: UTType {
        .item
    }

    @MainActor
    private func importSelectedConfigurations() async {
        let updateconfigurations = UpdateConfigurations(
            profile: rsyncUIdata.profile,
            configurations: rsyncUIdata.configurations
        )
        let importedConfigurations = selecteduuids.isEmpty
            ? configurations
            : configurations.filter { selecteduuids.contains($0.id) }
        rsyncUIdata.configurations = await updateconfigurations
            .addImportConfigurations(importedConfigurations)
        if SharedReference.shared.duplicatecheck,
           let configurations = rsyncUIdata.configurations {
            VerifyDuplicates(configurations)
        }
        activeSheet = nil
    }

    private func close() {
        activeSheet = nil
        dismiss()
    }
}
