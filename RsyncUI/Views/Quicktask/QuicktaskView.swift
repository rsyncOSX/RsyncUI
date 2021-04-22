//
//  QuicktaskView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 02/04/2021.
//
// swiftlint:disable line_length

import SwiftUI

enum TypeofTaskQuictask: String, CaseIterable, Identifiable, CustomStringConvertible {
    case synchronize
    case syncremote

    var id: String { rawValue }
    var description: String { rawValue.localizedLowercase }
}

struct QuicktaskView: View {
    @State private var localcatalog: String = ""
    @State private var remotecatalog: String = ""
    @State private var selectedrsynccommand = TypeofTaskQuictask.synchronize
    @State private var remoteuser: String = ""
    @State private var remoteserver: String = ""
    @State private var donotaddtrailingslash: Bool = false
    @State private var dryrun: Bool = true

    // Executed labels
    @State private var executed = false
    @State private var output: [String]?
    @State private var presentsheetview = false
    @State private var showprogressview = false
    @State private var rsyncoutput: InprogressCountRsyncOutput?
    // Selected row in output
    @State private var valueselectedrow: String = ""

    var body: some View {
        Form {
            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            pickerselecttypeoftask

                            HStack {
                                ToggleView(NSLocalizedString("--dry-run", comment: "ssh"), $dryrun)

                                ToggleView(NSLocalizedString("Don´t add /", comment: "settings"), $donotaddtrailingslash)
                            }
                        }

                        VStack(alignment: .leading) {
                            localandremotecatalog

                            remoteuserandserver
                        }

                        if executed { notifyexecuted }
                    }

                    // For center
                    Spacer()
                }

                if showprogressview {
                    RotatingDotsIndicatorView()
                        .frame(width: 50.0, height: 50.0)
                        .foregroundColor(.red)
                }
            }

            VStack {
                Spacer()

                HStack {
                    Button(NSLocalizedString("Execute", comment: "QuicktaskView")) { getconfig() }
                        .buttonStyle(PrimaryButtonStyle())

                    Spacer()

                    Button(NSLocalizedString("View", comment: "QuicktaskView")) { presentoutput() }
                        .buttonStyle(PrimaryButtonStyle())
                        .sheet(isPresented: $presentsheetview) { viewoutput }
                }
            }
        }
        .lineSpacing(2)
        .padding()
    }

    var pickerselecttypeoftask: some View {
        Picker(NSLocalizedString("Task", comment: "QuicktaskView") + ":",
               selection: $selectedrsynccommand) {
            ForEach(TypeofTaskQuictask.allCases) { Text($0.description)
                .tag($0)
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .frame(width: 180)
    }

    // Add and edit text values
    var setlocalcatalog: some View {
        EditValue(250, NSLocalizedString("Add localcatalog - required", comment: "QuicktaskView"), $localcatalog)
    }

    var setremotecatalog: some View {
        EditValue(250, NSLocalizedString("Add remotecatalog - required", comment: "QuicktaskView"), $remotecatalog)
    }

    // Headers (in sections)
    var headerlocalremote: some View {
        Text(NSLocalizedString("Catalog parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var localandremotecatalog: some View {
        Section(header: headerlocalremote) {
            // localcatalog
            EditValue(250, NSLocalizedString("Add source catalog", comment: "QuicktaskView"), $localcatalog)

            // remotecatalog
            EditValue(250, NSLocalizedString("Add destination catalog", comment: "QuicktaskView"), $remotecatalog)
        }
    }

    var setremoteuser: some View {
        EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
    }

    var setremoteserver: some View {
        EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
    }

    var headerremote: some View {
        Text(NSLocalizedString("Remote parameters", comment: "QuicktaskView"))
            .modifier(FixedTag(200, .leading))
    }

    var remoteuserandserver: some View {
        Section(header: headerremote) {
            // Remote user
            EditValue(250, NSLocalizedString("Add remote user", comment: "QuicktaskView"), $remoteuser)
            // Remote server
            EditValue(250, NSLocalizedString("Add remote server", comment: "QuicktaskView"), $remoteserver)
        }
    }

    // Output
    var viewoutput: some View {
        OutputRsyncView(isPresented: $presentsheetview,
                        output: $output,
                        valueselectedrow: $valueselectedrow)
    }

    var notifyexecuted: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1))
            Text(NSLocalizedString("Executed", comment: "settings"))
                .font(.title3)
                .foregroundColor(Color.blue)
        }
        .frame(width: 120, height: 20, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.gray, lineWidth: 2))
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
        let getdata = AppendConfig(selectedrsynccommand.rawValue,
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
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputProcess())
        // Start progressview
        showprogressview = true
        let command = RsyncProcessCmdCombineClosure(arguments: arguments,
                                                    config: nil,
                                                    processtermination: processtermination,
                                                    filehandler: filehandler)
        command.executeProcess(outputprocess: rsyncoutput?.myoutputprocess)
    }

    func processtermination() {
        // Stop progressview
        showprogressview = false
        rsyncoutput?.setoutput()
        output = rsyncoutput?.getoutput()

        executed = true
        // Show updated for 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            executed = false
        }
    }

    func filehandler() {}
}
