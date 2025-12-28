//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

struct RsyncParametersView: View {
    @Bindable var rsyncUIdata: RsyncUIconfigurations
    @Binding var selecteduuids: Set<SynchronizeConfiguration.ID>

    @State private var parameters = ObservableParametersRsync()
    @State private var selectedconfig: SynchronizeConfiguration?
    // @State private var selecteduuids = Set<SynchronizeConfiguration.ID>()
    // @State private var selectedrsynccommand = RsyncCommand.synchronize_data
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    // Backup switch
    @State var backup: Bool = false
    // Present a help sheet
    @State private var showhelp: Bool = false
    // Present arguments view
    @State private var presentarguments: Bool = false

    var body: some View {
        NavigationStack {
            HStack {
                VStack(alignment: .leading) {
                    if notifydataisupdated {
                        ConditionalGlassButton(
                            systemImage: "arrow.down",
                            text: "Update",
                            helpText: "Update parameters"
                        ) {
                            saveRsyncParameters()
                            selecteduuids.removeAll()
                        }
                        .disabled(selectedconfig == nil)
                        .padding(.bottom, 10)

                    } else {
                        ConditionalGlassButton(
                            systemImage: "plus",
                            text: "Add",
                            helpText: "Save parameters"
                        ) {
                            saveRsyncParameters()
                        }
                        .disabled(selectedconfig == nil)
                        .padding(.bottom, 10)
                    }

                    Section(header: Text("Parameters for rsync, select task to add")
                        .font(.title3)
                        .fontWeight(.bold)) {
                            // .foregroundColor(.blue)) {
                            EditRsyncParameter(400, $parameters.parameter8)
                                .onChange(of: parameters.parameter8) {
                                    parameters.configuration?.parameter8 = parameters.parameter8
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter9)
                                .onChange(of: parameters.parameter9) {
                                    parameters.configuration?.parameter9 = parameters.parameter9
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter10)
                                .onChange(of: parameters.parameter10) {
                                    parameters.configuration?.parameter10 = parameters.parameter10
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter11)
                                .onChange(of: parameters.parameter11) {
                                    parameters.configuration?.parameter11 = parameters.parameter11
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter12)
                                .onChange(of: parameters.parameter12) {
                                    parameters.configuration?.parameter12 = parameters.parameter12
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter13)
                                .onChange(of: parameters.parameter13) {
                                    parameters.configuration?.parameter13 = parameters.parameter13
                                }
                                .disabled(selectedconfig == nil)
                            EditRsyncParameter(400, $parameters.parameter14)
                                .onChange(of: parameters.parameter14) {
                                    parameters.configuration?.parameter14 = parameters.parameter14
                                }
                                .disabled(selectedconfig == nil)
                        }

                    Section(header: Text("Task specific SSH parameter")
                        .font(.title3)
                        .fontWeight(.bold)
                        // .foregroundColor(.blue)
                    ) {
                        HStack {
                            setsshpath
                                .disabled(selectedconfig == nil)

                            setsshport
                                .disabled(selectedconfig == nil)
                        }
                    }

                    Section(header: Text("Backup switch & Show rsync command")
                        .font(.title3)
                        .fontWeight(.bold)) {
                            HStack {
                                Toggle("", isOn: $backup)
                                    .toggleStyle(.switch)
                                    .onChange(of: backup) {
                                        guard selectedconfig != nil else {
                                            backup = false
                                            return
                                        }
                                        parameters.setbackup()
                                    }
                                    .onTapGesture {
                                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                            backup.toggle()
                                        }
                                    }
                                    .disabled(selectedconfig == nil)

                                Toggle("", isOn: $parameters.showdetails)
                                    .toggleStyle(.switch)
                                    .disabled(selectedconfig == nil)
                            }
                        }

                    if let selectedconfig {
                        let isDeletePresent = selectedconfig.parameter4 == "--delete"
                        let headerText = isDeletePresent ? "Remove --delete parameter" : "Add --delete parameter"
                        Section(header: Text(headerText)
                            .foregroundColor(deleteparameterpresent ? Color(.red) : Color(.blue))
                            .fontWeight(.bold)
                            .font(.title3)) {
                                Toggle("", isOn: $parameters.adddelete)
                                    .toggleStyle(.switch)
                                    .onChange(of: parameters.adddelete) {
                                        parameters.adddelete(parameters.adddelete)
                                    }
                                    .disabled(selecteduuids.isEmpty == true)
                                    .onTapGesture {
                                        withAnimation(Animation.easeInOut(duration: true ? 0.35 : 0)) {
                                            backup.toggle()
                                        }
                                    }
                            }
                        Spacer()
                    } else {
                        Spacer()
                    }
                }

                Spacer()

                VStack(alignment: .center) {
                    if deleteparameterpresent {
                        HStack {
                            Text("If \(Text("red Synchronize ID").foregroundColor(.red)) click")

                            Button {
                                parameters.whichhelptext = 1
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information")
                        }
                        .padding(.bottom, 10)

                    } else {
                        HStack {
                            Text("To add --delete click")

                            Button {
                                parameters.whichhelptext = 2
                                showhelp = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                            }
                            .buttonStyle(HelpButtonStyle(redorwhitebutton: deleteparameterpresent))

                            Text("for more information")
                        }
                        .padding(.bottom, 10)
                    }

                    ConfigurationsTableDataView(selecteduuids: $selecteduuids,
                                                configurations: rsyncUIdata.configurations)
                        .frame(maxWidth: .infinity, maxHeight: 330)
                        .onChange(of: selecteduuids) {
                            if let configurations = rsyncUIdata.configurations {
                                if let index = configurations.firstIndex(where: { $0.id == selecteduuids.first }) {
                                    selectedconfig = configurations[index]
                                    parameters.setvalues(configurations[index])
                                    if configurations[index].parameter12 != "--backup" {
                                        backup = false
                                    }
                                } else {
                                    selectedconfig = nil
                                    parameters.setvalues(selectedconfig)
                                    backup = false
                                    parameters.showdetails = false
                                }
                            }
                        }

                    Spacer()
                }
            }

            Spacer()

            if selectedconfig != nil {
                if parameters.showdetails {
                    if let selectedconfig {
                        RsyncCommandView(config: selectedconfig)
                    }
                }
            }

            if focusaborttask { labelaborttask }
        }
        .onAppear {
            if selecteduuids.count > 0 {
                // Reset preselected tasks, must do a few seconds timout
                // before clearing it out
                Task {
                    try await Task.sleep(seconds: 2)
                    selecteduuids.removeAll()
                }
            }
        }
        .onChange(of: rsyncUIdata.profile) {
            selectedconfig = nil
            // selecteduuids.removeAll()
            // done on Sidebar Main view
            parameters.setvalues(selectedconfig)
            backup = false
        }
        .sheet(isPresented: $showhelp) {
            switch parameters.whichhelptext {
            case 1:
                HelpView(text: parameters.helptext1, add: true, deleteparameterpresent: true)
            case 2:
                HelpView(text: parameters.helptext2, add: true, deleteparameterpresent: false)
            default:
                HelpView(text: parameters.helptext1, add: true, deleteparameterpresent: true)
            }
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .toolbar(content: {
            ToolbarItem {
                Button {
                    presentarguments = true
                } label: {
                    Image(systemName: "command")
                }
                .help("Show arguments")
            }
        })
        .navigationTitle("Parameters for rsync: profile \(rsyncUIdata.profile ?? "Default")")
        .navigationDestination(isPresented: $presentarguments) {
            ArgumentsView(rsyncUIdata: rsyncUIdata)
        }
        .padding()
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear {
                focusaborttask = false
                abort()
            }
    }

    var setsshpath: some View {
        EditValueErrorScheme(300, "ssh-keypath and identityfile",
                             $parameters.sshkeypathandidentityfile,
                             parameters.sshkeypath(parameters.sshkeypathandidentityfile))
    }

    var setsshport: some View {
        EditValueErrorScheme(150, "ssh-port", $parameters.sshport,
                             parameters.setsshport(parameters.sshport))
    }

    var notifydataisupdated: Bool {
        guard let selectedconfig else { return false }
        if parameters.parameter8 != (selectedconfig.parameter8 ?? "") ||
            parameters.parameter9 != (selectedconfig.parameter9 ?? "") ||
            parameters.parameter10 != (selectedconfig.parameter10 ?? "") ||
            parameters.parameter11 != (selectedconfig.parameter11 ?? "") ||
            parameters.parameter12 != (selectedconfig.parameter12 ?? "") ||
            parameters.parameter13 != (selectedconfig.parameter13 ?? "") ||
            parameters.parameter14 != (selectedconfig.parameter14 ?? "") ||
            parameters.parameter14 != (selectedconfig.parameter14 ?? "") ||
            parameters.adddelete == (selectedconfig.parameter4 == nil) ||
            // parameters.sshport != String(selectedconfig.sshport ?? -1) ||
            parameters.sshkeypathandidentityfile != (selectedconfig.sshkeypathandidentityfile ?? "") {
            return true
        }
        return false
    }

    var deleteparameterpresent: Bool {
        let parameter = rsyncUIdata.configurations?.filter { $0.parameter4?.isEmpty == false }
        return parameter?.count ?? 0 > 0
    }
}

extension RsyncParametersView {
    func saveRsyncParameters() {
        if let updatedconfiguration = parameters.updatersyncparameters(),
           let configurations = rsyncUIdata.configurations {
            let updateconfigurations =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: configurations)
            updateconfigurations.updateConfiguration(updatedconfiguration, true)
            rsyncUIdata.configurations = updateconfigurations.configurations
            parameters.reset()
            selectedconfig = nil
        }
    }
}
