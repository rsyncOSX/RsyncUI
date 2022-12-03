//
//  RsyncParametersView.swift
//  RsyncParametersView
//
//  Created by Thomas Evensen on 18/08/2021.
//
// swiftlint:disable line_length

import SwiftUI

struct RsyncParametersView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIconfigurations
    @StateObject var parameters = ObserveableParametersRsync()
    @Binding var selectedprofile: String?
    @Binding var reload: Bool

    @State private var selectedconfig: Configuration?
    @State private var rsyncoutput: InprogressCountRsyncOutput?

    @State private var showprogressview = false
    @State private var presentsheetview = false
    @State private var valueselectedrow: String = ""
    @State private var numberoffiles: Int = 0

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        EditRsyncParameter(450, $parameters.parameter8)
                        EditRsyncParameter(450, $parameters.parameter9)
                        EditRsyncParameter(450, $parameters.parameter10)
                        EditRsyncParameter(450, $parameters.parameter11)
                        EditRsyncParameter(450, $parameters.parameter12)
                        EditRsyncParameter(450, $parameters.parameter13)
                        EditRsyncParameter(450, $parameters.parameter14)

                        Spacer()
                    }

                    VStack {
                        ConfigurationsListSmall(selectedconfig: $selectedconfig.onChange {
                            parameters.setvalues(selectedconfig)
                        },
                        reload: $reload)
                    }
                }

                HStack {
                    RsyncCommandView(config: $parameters.configuration)

                    Spacer()
                }

                Spacer()

                HStack {
                    Button("Linux") {
                        parameters.suffixlinux = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("FreeBSD") {
                        parameters.suffixfreebsd = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Backup") {
                        parameters.backup = true
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Spacer()

                    Button("Verify") {
                        if let configuration = parameters.updatersyncparameters() {
                            Task {
                                await verify(config: configuration)
                            }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Save") { saversyncparameters() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .sheet(isPresented: $presentsheetview) { viewoutput }
                .padding()
            }

            if showprogressview {
                RotatingDotsIndicatorView()
                    .frame(width: 50.0, height: 50.0)
                    .foregroundColor(.red)
            }
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

extension RsyncParametersView {
    func saversyncparameters() {
        if let configuration = parameters.updatersyncparameters() {
            let updateconfiguration =
                UpdateConfigurations(profile: rsyncUIdata.configurationsfromstore?.profile,
                                     configurations: rsyncUIdata.configurationsfromstore?.configurationData.getallconfigurations())
            updateconfiguration.updateconfiguration(configuration, true)
        }
        parameters.reset()
        selectedconfig = nil
        reload = true
    }

    @MainActor
    func verify(config: Configuration) async {
        let arguments = ArgumentsSynchronize(config: config).argumentssynchronize(dryRun: true, forDisplay: false)
        rsyncoutput = InprogressCountRsyncOutput(outputprocess: OutputfromProcess())
        showprogressview = true
        let process = RsyncProcessAsync(arguments: arguments,
                                        config: config,
                                        processtermination: processtermination)
        await process.executeProcess()
    }

    func processtermination(outputfromrsync: [String]?, hiddenID _: Int?) {
        showprogressview = false
        rsyncoutput?.setoutput(data: outputfromrsync)
        presentsheetview = true
    }
}
