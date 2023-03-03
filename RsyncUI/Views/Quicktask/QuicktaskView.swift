//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/04/2021.
//

import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct QuicktaskView: View {
    @Binding var showcompleted: Bool

    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var donotaddtrailingslash: Bool = false
    @State private var dryrun: Bool = true

    // Executed labels
    @State private var presentsheetview = false
    @State private var showprogressview = false
    @State private var rsyncoutput: InprogressCountRsyncOutput?
    // Selected row in output
    @State private var valueselectedrow: String = ""
    // Focus buttons from the menu
    @State private var focusaborttask: Bool = false

    var choosecatalog = true

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState private var focusField: QuicktaskField?

    // @State private var numberoffiles: Int = 0

    var body: some View {
        ZStack {
            Spacer()

            // Column 1
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    pickerselecttypeoftask

                    HStack {
                        ToggleViewDefault("--dry-run", $dryrun)

                        ToggleViewDefault(NSLocalizedString("Don´t add /", comment: ""), $donotaddtrailingslash)
                    }
                    .padding()
                }

                VStack(alignment: .leading) {
                    if selectedrsynccommand == .synchronize {
                        localandremotecatalog
                    } else {
                        localandremotecatalogsyncremote
                    }

                    remoteuserandserver
                }
            }

            if showprogressview {
                ProgressView()
                    .frame(width: 50.0, height: 50.0)
            }

            if focusaborttask { labelaborttask }
        }
        .onSubmit {
            switch focusField {
            case .localcatalogField:
                focusField = .remotecatalogField
            case .remotecatalogField:
                focusField = .remoteuserField
            case .remoteuserField:
                focusField = .remoteserverField
            case .remoteserverField:
                focusField = nil
                dryrun = true
            default:
                return
            }
        }
        .onAppear {
            focusField = .localcatalogField
        }
        .focusedSceneValue(\.aborttask, $focusaborttask)

        VStack {
            Spacer()

            HStack {
                Button("Execute") {
                    getconfig()
                }
                .buttonStyle(PrimaryButtonStyle())

                Spacer()

                Button("Output") { presentsheetview = true }
                    .buttonStyle(PrimaryButtonStyle())
                    .sheet(isPresented: $presentsheetview) { viewoutput }

                Button("Abort") { abort() }
                    .buttonStyle(AbortButtonStyle())
                    .tooltip("Shortcut ⌘A")
            }
        }
    }

    var labelaborttask: some View {
        Label("", systemImage: "play.fill")
            .onAppear(perform: {
                focusaborttask = false
                abort()
            })
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "") + ":",
               selection: $selectedrsynccommand.onChange {
                   resetform()
               }) {
            ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text("Catalog parameters")
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            HStack {
                EditValue(300, NSLocalizedString("Add local catalog - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $localcatalog, choosecatalog: choosecatalog)
            }

            // remotecatalog
            HStack {
                EditValue(300, NSLocalizedString("Add remote catalog - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var localandremotecatalogsyncremote: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            HStack {
                EditValue(300, NSLocalizedString("Add remote as local catalog - required", comment: ""), $localcatalog)
                    .focused($focusField, equals: .localcatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $localcatalog, choosecatalog: choosecatalog)
            }

            // remotecatalog
            HStack {
                EditValue(300, NSLocalizedString("Add local as remote catalog - required", comment: ""), $remotecatalog)
                    .focused($focusField, equals: .remotecatalogField)
                    .textContentType(.none)
                    .submitLabel(.continue)

                OpencatalogView(catalog: $remotecatalog, choosecatalog: choosecatalog)
            }
        }
    }

    var headerremote: some View {
        Text("Remote parameters")
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(300, NSLocalizedString("Add remote user", comment: ""), $remoteuser)
                .focused($focusField, equals: .remoteuserField)
                .textContentType(.none)
                .submitLabel(.continue)
            // Remote server
            EditValue(300, NSLocalizedString("Add remote server", comment: ""), $remoteserver)
                .focused($focusField, equals: .remoteserverField)
                .textContentType(.none)
                .submitLabel(.return)
        }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: rsyncoutput?.getoutput() ?? [])
    }
}

extension QuicktaskView {
    func resetform() {
        localcatalog = ""
        remotecatalog = ""
        remoteuser = ""
        remoteserver = ""
    }

    func getconfig() {
        let getdata = AppendTask(selectedrsynccommand.rawValue,
                                 localcatalog,
                                 remotecatalog,
                                 donotaddtrailingslash,
                                 remoteuser,
                                 remoteserver,
                                 "",
                                 nil,
                                 nil,
                                 nil,
                                 nil,
                                 nil)
        // If newconfig is verified add it
        if let newconfig = VerifyConfiguration().verify(getdata) {
            // Now can prepare for execute.
            Task {
                await execute(config: newconfig, dryrun: dryrun)
            }
        }
    }

    @MainActor
    func execute(config: Configuration, dryrun: Bool) async {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        // Start progressview
        showprogressview = true
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }

    func abort() {
        _ = InterruptProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        // Stop progressview
        showprogressview = false
        rsyncoutput?.setoutput()
        showcompleted = true
        rsyncoutput?.setoutput(data: outputfromrsync)
    }
}
