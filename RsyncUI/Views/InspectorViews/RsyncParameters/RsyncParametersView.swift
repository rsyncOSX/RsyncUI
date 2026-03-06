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
        VStack(alignment: .leading, spacing: 12) {
            addupdateButton

            VStack(alignment: .leading, spacing: 8) {
                EditRsyncParameter(350, $parameters.parameter8)
                    .onChange(of: parameters.parameter8) { parameters.configuration?.parameter8 = parameters.parameter8 }
                EditRsyncParameter(350, $parameters.parameter9)
                    .onChange(of: parameters.parameter9) { parameters.configuration?.parameter9 = parameters.parameter9 }
                EditRsyncParameter(350, $parameters.parameter10)
                    .onChange(of: parameters.parameter10) { parameters.configuration?.parameter10 = parameters.parameter10 }
                EditRsyncParameter(350, $parameters.parameter11)
                    .onChange(of: parameters.parameter11) { parameters.configuration?.parameter11 = parameters.parameter11 }
                EditRsyncParameter(350, $parameters.parameter12)
                    .onChange(of: parameters.parameter12) { parameters.configuration?.parameter12 = parameters.parameter12 }
                EditRsyncParameter(350, $parameters.parameter13)
                    .onChange(of: parameters.parameter13) { parameters.configuration?.parameter13 = parameters.parameter13 }
                EditRsyncParameter(350, $parameters.parameter14)
                    .onChange(of: parameters.parameter14) { parameters.configuration?.parameter14 = parameters.parameter14 }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Task specific SSH parameter").font(.headline)
                VStack(alignment: .leading, spacing: 8) {
                    setsshpath(path: $parameters.sshkeypathandidentityfile,
                               placeholder: "set SSH keypath and identityfile",
                               selectedValue: parameters.sshkeypathandidentityfile)
                    sshportfield(port: $parameters.sshport,
                                 placeholder: "set SSH port",
                                 selectedValue: parameters.sshport)
                }
            }

            let isDeletePresent = selectedconfig?.parameter4 == "--delete"
            let headerText = isDeletePresent ? "Remove --delete parameter" : "Add --delete parameter"

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(headerText)
                        .font(.headline)
                        .foregroundColor(deleteparameterpresent ? Color(.red) : Color(.blue))
                    Toggle("--delete", isOn: $parameters.adddelete)
                        .toggleStyle(.switch)
                        .onChange(of: parameters.adddelete) { parameters.adddelete(parameters.adddelete) }
                        .disabled(selecteduuids.isEmpty)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Append Backup parameter")
                        .font(.headline)
                    Toggle("Backup", isOn: $backup)
                        .toggleStyle(.switch)
                        .onChange(of: backup) {
                            guard !selecteduuids.isEmpty else {
                                backup = false
                                return
                            }
                            parameters.setbackup()
                        }
                }
            }
        }
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
