//
//  NavigationRsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//

import SwiftUI

enum ParametersDestinationView: String, Identifiable {
    case defaultparameters, verify
    var id: String { rawValue }
}

struct ParametersTasks: Hashable, Identifiable {
    let id = UUID()
    var task: ParametersDestinationView
}

struct NavigationRsyncParametersView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @State private var parameters = ObservableParametersRsync()

    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var rsyncoutput: ObservableRsyncOutput?

    @State private var showprogressview = false
    @State private var valueselectedrow: String = ""
    @State private var numberoffiles: Int = 0
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var selectedrsynccommand = RsyncCommand.synchronize

    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    // Which view to show
    @State var path: [ParametersTasks] = []

    var body: some View {
        NavigationStack(path: $path) {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }

                    EditRsyncParameter(450, $parameters.parameter8)
                        .onChange(of: parameters.parameter8) {
                            parameters.configuration?.parameter8 = parameters.parameter8
                        }
                    EditRsyncParameter(450, $parameters.parameter9)
                        .onChange(of: parameters.parameter9) {
                            parameters.configuration?.parameter9 = parameters.parameter9
                        }
                    EditRsyncParameter(450, $parameters.parameter10)
                        .onChange(of: parameters.parameter10) {
                            parameters.configuration?.parameter10 = parameters.parameter10
                        }
                    EditRsyncParameter(450, $parameters.parameter11)
                        .onChange(of: parameters.parameter11) {
                            parameters.configuration?.parameter11 = parameters.parameter11
                        }
                    EditRsyncParameter(450, $parameters.parameter12)
                        .onChange(of: parameters.parameter12) {
                            parameters.configuration?.parameter12 = parameters.parameter12
                        }
                    EditRsyncParameter(450, $parameters.parameter13)
                        .onChange(of: parameters.parameter13) {
                            parameters.configuration?.parameter13 = parameters.parameter13
                        }
                    EditRsyncParameter(450, $parameters.parameter14)
                        .onChange(of: parameters.parameter14) {
                            parameters.configuration?.parameter14 = parameters.parameter14
                        }

                    Spacer()

                    HStack {
                        Button("Linux") {
                            parameters.setsuffixlinux()
                        }
                        .buttonStyle(ColorfulButtonStyle())

                        Button("FreeBSD") {
                            parameters.setsuffixfreebsd()
                        }
                        .buttonStyle(ColorfulButtonStyle())

                        Button("Backup") {
                            parameters.setbackup()
                        }
                        .buttonStyle(ColorfulButtonStyle())
                    }

                    Spacer()
                }

                ListofTasksLightView(selecteduuids: $selecteduuids)
                    .frame(maxWidth: .infinity)
                    .onChange(of: selecteduuids) {
                        let selected = rsyncUIdata.configurations?.filter { config in
                            selecteduuids.contains(config.id)
                        }
                        if (selected?.count ?? 0) == 1 {
                            if let config = selected {
                                selectedconfig = config[0]
                                parameters.setvalues(selectedconfig)
                            }
                        } else {
                            selectedconfig = nil
                            parameters.setvalues(selectedconfig)
                        }
                    }

                if focusaborttask { labelaborttask }
            }

            ZStack {
                RsyncCommandView(config: $parameters.configuration,
                                 selectedrsynccommand: $selectedrsynccommand)

                if showprogressview { AlertToast(displayMode: .alert, type: .loading) }
            }
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .alert(isPresented: $parameters.alerterror,
               content: { Alert(localizedError: parameters.error)
               })
        .toolbar(content: {
            ToolbarItem {
                Button {
                    path.append(ParametersTasks(task: .defaultparameters))
                } label: {
                    Image(systemName: "fossil.shell.fill")
                }
            }

            ToolbarItem {
                Button {
                    if let configuration = parameters.updatersyncparameters() {
                        Task {
                            await verify(config: configuration)
                        }
                    }
                } label: {
                    Image(systemName: "flag.checkered")
                }
                .help("Verify")
            }

            ToolbarItem {
                Button {
                    saversyncparameters()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("Update task")
            }
        })
        .navigationDestination(for: ParametersTasks.self) { which in
            makeView(view: which.task)
        }
        .padding()
    }

    @ViewBuilder
    func makeView(view: ParametersDestinationView) -> some View {
        switch view {
        case .defaultparameters:
            NavigationRsyncDefaultParametersView(reload: $reload, path: $path)
        case .verify:
            NavigationOutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    var setsshpath: some View {
        EditValue(250, "Local ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = parameters.configuration?.sshkeypathandidentityfile {
                    parameters.sshkeypathandidentityfile = sshkeypath
                }
            })
            .onChange(of: parameters.sshkeypathandidentityfile) {
                parameters.sshkeypathandidentiyfile(parameters.sshkeypathandidentityfile)
                parameters.setvalues(selectedconfig)
            }
    }

    var setsshport: some View {
        EditValue(250, "Local ssh port", $parameters.sshport)
            .onAppear(perform: {
                if let sshport = parameters.configuration?.sshport {
                    parameters.sshport = String(sshport)
                }
            })
            .onChange(of: parameters.sshport) {
                parameters.setsshport(parameters.sshport)
                parameters.setvalues(selectedconfig)
            }
    }
}

extension NavigationRsyncParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }

    func verify(config: Configuration) async {
        var arguments: [String]?
        switch selectedrsynccommand {
        case .synchronize:
            arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: false)
        case .restore:
            arguments = ArgumentsRestore(config: config, restoresnapshotbyfiles: false).argumentsrestore(dryRun: true, forDisplay: false, tmprestore: true)
        case .verify:
            arguments = ArgumentsVerify(config: config).argumentsverify(forDisplay: false)
        }
        rsyncoutput = ObservableRsyncOutput()
        showprogressview = true
        let process = await RsyncProcessAsync(arguments: arguments,
                                              config: config,
                                              processtermination: processtermination)
        await process.executeProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(outputfromrsync)
        path.append(ParametersTasks(task: .verify))
    }

    func abort() {
        showprogressview = false
        _ = InterruptProcess()
    }
}

// swiftlint:enable line_length
