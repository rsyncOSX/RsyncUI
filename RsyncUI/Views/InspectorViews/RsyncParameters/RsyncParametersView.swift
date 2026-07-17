//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selectedTab: InspectorTab
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State var parameters = ObservableParametersRsync()
    @State var selectedconfig: SynchronizeConfiguration?
    /// Backup switch
    @State var backup: Bool = false
    /// Present arguments view
    @State var presentarguments: Bool = false

    var body: some View {
        Form {
            Section("Parameters") {
                EditRsyncParameter($parameters.parameter8)
                    .onChange(of: parameters.parameter8) { parameters.configuration?.parameter8 = parameters.parameter8 }
                EditRsyncParameter($parameters.parameter9)
                    .onChange(of: parameters.parameter9) { parameters.configuration?.parameter9 = parameters.parameter9 }
                EditRsyncParameter($parameters.parameter10)
                    .onChange(of: parameters.parameter10) { parameters.configuration?.parameter10 = parameters.parameter10 }
                EditRsyncParameter($parameters.parameter11)
                    .onChange(of: parameters.parameter11) { parameters.configuration?.parameter11 = parameters.parameter11 }
                EditRsyncParameter($parameters.parameter12)
                    .onChange(of: parameters.parameter12) { parameters.configuration?.parameter12 = parameters.parameter12 }
                EditRsyncParameter($parameters.parameter13)
                    .onChange(of: parameters.parameter13) { parameters.configuration?.parameter13 = parameters.parameter13 }
                EditRsyncParameter($parameters.parameter14)
                    .onChange(of: parameters.parameter14) { parameters.configuration?.parameter14 = parameters.parameter14 }
            }

            Section("SSH") {
                TextField("SSH keypath and identityfile", text: $parameters.sshkeypathandidentityfile)
                TextField("SSH port", text: $parameters.sshport)
            }

            Section("Backup") {
                Toggle("--backup Parameter", isOn: $backup)
                    .toggleStyle(.switch)
                    .onChange(of: backup) {
                        guard !selecteduuids.isEmpty else {
                            backup = false
                            return
                        }
                        parameters.setbackup()
                    }
            }

            Section {
                HStack {
                    Toggle(isOn: $parameters.adddelete, label: {
                        Link(destination: URL(string: "https://rsyncui.netlify.app/docs/getting-started/important/")!) {
                            Text("--delete Parameter")
                            Image(systemName: "info.circle")
                        }
                        .foregroundStyle(.red)

                    })
                    .toggleStyle(.switch)
                    .onChange(of: parameters.adddelete) { parameters.adddelete(parameters.adddelete) }
                    .disabled(selecteduuids.isEmpty)
                    .tint(.red)
                }
            }
            header: {
                Text("Danger Zone")
                    .foregroundStyle(.red)
            }

            updateButton
        }
        .formStyle(.grouped)
        .onAppear { handleSelectionChange() }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            // selecteduuids.removeAll()
            // done on Sidebar Main view
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .padding()
    }
}
