//
//  RsyncDefaultParametersView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 21/03/2021.
//
// swiftlint:disable line_length

import Combine
import SwiftUI

struct RsyncDefaultParametersView: View {
    @SwiftUI.Environment(\.rsyncUIData) private var rsyncUIdata
    @Binding var reload: Bool

    @State private var parameters = ObservableParametersDefault()
    @State private var selectedconfig: Configuration?
    @State private var selectedrsynccommand = RsyncCommand.synchronize
    @State private var rsyncoutput: ObservableRsyncOutput?
    @State private var showprogressview = false
    @State private var presentsheetview = false
    @State private var valueselectedrow: String = ""
    @State private var selecteduuids = Set<Configuration.ID>()
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false
    // Combine for debounce of sshport and keypath
    @State var publisherport = PassthroughSubject<String, Never>()
    @State var publisherkeypath = PassthroughSubject<String, Never>()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Section(header: headerssh) {
                        setsshpath

                        setsshport
                    }

                    Section(header: headerremove) {
                        VStack(alignment: .leading) {
                            ToggleViewDefault("-e ssh", $parameters.removessh)
                                .onChange(of: parameters.removessh) {
                                    parameters.deletessh(parameters.removessh)
                                }
                            ToggleViewDefault("--compress", $parameters.removecompress)
                                .onChange(of: parameters.removecompress) {
                                    parameters.deletecompress(parameters.removecompress)
                                }
                            ToggleViewDefault("--delete", $parameters.removedelete)
                                .onChange(of: parameters.removedelete) {
                                    parameters.deletedelete(parameters.removedelete)
                                }
                        }
                    }

                    Section(header: headerdaemon) {
                        ToggleViewDefault("daemon", $parameters.daemon)
                    }

                    Spacer()
                }

                VStack(alignment: .leading) {
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

                    ZStack {
                        HStack(alignment: .center) {
                            RsyncCommandView(config: $parameters.configuration, selectedrsynccommand: $selectedrsynccommand)
                        }

                        if showprogressview { AlertToast(displayMode: .alert, type: .loading) }
                    }
                }

                if focusaborttask { labelaborttask }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Verify") {
                    if let configuration = parameters.updatersyncparameters() {
                        Task {
                            await verify(config: configuration)
                        }
                    }
                }
                .buttonStyle(ColorfulButtonStyle())

                Button("Save") { saversyncparameters() }
                    .buttonStyle(ColorfulButtonStyle())
            }
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)
        .padding()
        .sheet(isPresented: $presentsheetview) { viewoutput }
        .alert(isPresented: $parameters.alerterror,
               content: { Alert(localizedError: parameters.error)
               })
    }

    // Header remove
    var headerremove: some View {
        Text("Remove default rsync parameters")
    }

    // Ssh header
    var headerssh: some View {
        Text("Set ssh keypath and identityfile")
    }

    // Daemon header
    var headerdaemon: some View {
        Text("Enable rsync daemon")
    }

    var setsshpath: some View {
        EditValue(250, "Local ssh keypath and identityfile",
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
                parameters.sshkeypath(parameters.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(250, "Local ssh port", $parameters.sshport)
            .onChange(of: parameters.sshport) {
                publisherport.send(parameters.sshport)
            }
            .onReceive(
                publisherport.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                parameters.setsshport(parameters.sshport)
            }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(output: rsyncoutput?.getoutput() ?? [])
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }
}

extension RsyncDefaultParametersView {
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
        presentsheetview = true
    }

    func abort() {
        showprogressview = false
        _ = InterruptProcess()
    }
}

// swiftlint:enable line_length
