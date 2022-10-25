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
    var choosecatalog = true

    enum QuicktaskField: Hashable {
        case localcatalogField
        case remotecatalogField
        case remoteuserField
        case remoteserverField
    }

    @FocusState private var focusField: QuicktaskField?

    @State private var numberoffiles: Int = 0

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
                RotatingDotsIndicatorView(count: 5)
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }
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

        VStack {
            Spacer()

            HStack {
                Button("Execute") { getconfig() }
                    .buttonStyle(PrimaryButtonStyle())

                Spacer()

                Button("Log") { presentoutput() }
                    .buttonStyle(PrimaryButtonStyle())
                    .sheet(isPresented: $presentsheetview) { viewoutput }

                Button("Abort") { abort() }
                    .buttonStyle(AbortButtonStyle())
            }
        }
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
                        valueselectedrow: $valueselectedrow,
                        numberoffiles: $numberoffiles,
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

    // Set output from rsync
    func presentoutput() {
        presentsheetview = true
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
            execute(config: newconfig, dryrun: dryrun)
        }
    }

    func execute(config: Configuration, dryrun: Bool) {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: dryrun, forDisplay: false)
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        // Start progressview
        showprogressview = true
        let command = RsyncProcess(arguments: arguments,
                                   config: nil,
                                   processtermination: processtermination,
                                   filehandler: filehandler)
        command.executeProcess(outputprocess: rsyncoutput?.myoutputprocess)
    }

    func abort() {
        _ = InterruptProcess()
    }

    func processtermination() {
        // Stop progressview
        showprogressview = false
        rsyncoutput?.setoutput()
        showcompleted = true
    }

    func filehandler() {}
}
