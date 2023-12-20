//
//  RsyncParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 20/11/2023.
//
// swiftlint:disable line_length

import Combine
import SwiftUI

enum ParametersDestinationView: String, Identifiable {
    case defaultparameters, verify
    var id: String { rawValue }
}

struct ParametersTasks: Hashable, Identifiable {
    let id = UUID()
    var task: ParametersDestinationView
}

struct RsyncParametersView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var reload: Bool

    @State private var parameters = ObservableParametersRsync()
    @State private var selectedconfig: Configuration?
    @State private var rsyncoutput: ObservableRsyncOutput?
    @State private var showprogressview = false
    @State private var valueselectedrow: String = ""
    @State private var selecteduuids = Set<Configuration.ID>()
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    // Which view to show
    @State var path: [ParametersTasks] = []
    // Combine for debounce of sshport and keypath
    @State var publisherport = PassthroughSubject<String, Never>()
    @State var publisherkeypath = PassthroughSubject<String, Never>()
    // Backup switch
    @State var backup: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            HStack {
                VStack(alignment: .leading) {
                    // Section(header: headerssh) {
                    HStack {
                        setsshpath

                        setsshport
                    }
                    // }

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

                    Toggle("Backup", isOn: $backup)
                        .toggleStyle(.switch)
                        .onChange(of: backup) {
                            guard selectedconfig != nil else {
                                backup = false
                                return
                            }
                            guard selectedconfig?.parameter12?.isEmpty ?? true == true,
                                  selectedconfig?.parameter13?.isEmpty ?? true == true
                            else {
                                backup = false
                                return
                            }
                            parameters.setbackup()
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
                            backup = false
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
                    Image(systemName: "house.fill")
                }
                .help("Default rsync parameters")
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
                .help("Verify task")
            }

            ToolbarItem {
                Button {
                    saversyncparameters()
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(Color(.blue))
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
            RsyncDefaultParametersView(reload: $reload, path: $path)
        case .verify:
            OutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var setsshpath: some View {
        EditValue(300, "Ssh keypath and identityfile",
                  $parameters.sshkeypathandidentityfile)
            .onChange(of: parameters.sshkeypathandidentityfile) {
                publisherkeypath.send(parameters.sshkeypathandidentityfile)
            }
            .onReceive(
                publisherkeypath.debounce(
                    for: .seconds(3),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                guard selectedconfig != nil else { return }
                parameters.sshkeypath(parameters.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(150, "Ssh port", $parameters.sshport)
            .onChange(of: parameters.sshport) {
                publisherport.send(parameters.sshport)
            }
            .onReceive(
                publisherport.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                guard selectedconfig != nil else { return }
                parameters.setsshport(parameters.sshport)
            }
    }
}

extension RsyncParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.profile,
                                     configurations: rsyncUIdata.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
            parameters.reset()
            selectedconfig = nil
            reload = true
        }
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
