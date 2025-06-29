//
//  Environmentsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import OSLog
import SwiftUI

struct Environmentsettings: View {
    @State private var environmentvalue: String = ""
    @State private var environment: String = ""
    @State private var dataischanged: Bool = false

    var body: some View {
        Form {
            Section {
                setenvironment

                setenvironmenvariable

            } header: {
                Text("Rsync environment")
            }

            if dataischanged {
                Section {
                    Button {
                        _ = WriteUserConfigurationJSON(UserConfiguration())
                        Logger.process.info("USER CONFIGURATION is SAVED")
                        dataischanged = false
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .help("Save")
                    .buttonStyle(ColorfulButtonStyle())
                } header: {
                    Text("Save userconfiguration")
                }
            }
        }
        .formStyle(.grouped)
    }

    var setenvironment: some View {
        EditValueScheme(400, NSLocalizedString("Environment", comment: ""), $environment)
            .onAppear(perform: {
                if let environmentstring = SharedReference.shared.environment {
                    environment = environmentstring
                }
            })
            .onChange(of: environment) {
                SharedReference.shared.environment = environment
                dataischanged = true
            }
    }

    var setenvironmenvariable: some View {
        EditValueScheme(400, NSLocalizedString("Environment variable", comment: ""), $environmentvalue)
            .onAppear(perform: {
                if let environmentvaluestring = SharedReference.shared.environmentvalue {
                    environmentvalue = environmentvaluestring
                }
            })
            .onChange(of: environmentvalue) {
                SharedReference.shared.environmentvalue = environmentvalue
                dataischanged = true
            }
    }
}
