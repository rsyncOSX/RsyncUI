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
    @State private var showsArguments = true
    @State private var showsSSH = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DisclosureGroup("Additional rsync arguments", isExpanded: $showsArguments) {
                ForEach(parameters.visibleArgumentSlots, id: \.self) { slot in
                    EditRsyncParameter(Binding(
                        get: { parameters.argument(in: slot) },
                        set: { parameters.setArgument($0, in: slot) }
                    ))
                }
                if parameters.canAddArgument {
                    Button("Add Argument", systemImage: "plus", action: parameters.addArgument)
                        .buttonStyle(.borderless)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        .disabled(selecteduuids.isEmpty)
                }
            }

            DisclosureGroup("SSH connection", isExpanded: $showsSSH) {
                HStack {
                    setsshpath(path: $parameters.sshkeypathandidentityfile,
                               placeholder: "set SSH keypath and identityfile",
                               selectedValue: parameters.sshkeypathandidentityfile)
                    sshportfield(port: $parameters.sshport,
                                 placeholder: "set SSH port",
                                 selectedValue: parameters.sshport)
                }
            }

            GroupBox("Destination behavior") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Delete destination items missing from the source", isOn: $parameters.adddelete)
                        .onChange(of: parameters.adddelete) { parameters.adddelete(parameters.adddelete) }
                        .disabled(selecteduuids.isEmpty)
                    if parameters.adddelete {
                        Label("File deletion is enabled. Synchronization may remove files from the destination.",
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Link("About rsync deletion", destination: URL(string: "https://rsyncui.netlify.app/docs/getting-started/important/")!)
                    Divider()
                    Toggle("Backup replaced files", isOn: Binding(
                        get: { parameters.backupIsEnabled },
                        set: { parameters.setbackup($0) }
                    ))
                    .disabled(selecteduuids.isEmpty)
                }
                .toggleStyle(.switch)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
            }
            HStack {
                Spacer()
                saveButton
            }
        }
        .onAppear { handleSelectionChange() }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            // selecteduuids.removeAll()
            // done on Sidebar Main view
            parameters.setvalues(selectedconfig)
        }
        .onChange(of: selecteduuids) {
            handleSelectionChange()
        }
        .padding()
    }
}
