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

    private func saveConfiguration() {
        let snapshot = UserConfiguration()
        Task { @MainActor in
            await WriteUserConfigurationJSON.write(snapshot)
        }
    }

    var body: some View {
        Form {
            Section(header: Text("Rsync environment")
                .font(.title3)
                .fontWeight(.bold)) {
                    setenvironment

                    setenvironmenvariable
                }
        }
        .formStyle(.grouped)
    }

    var setenvironment: some View {
        EditValueScheme(400, "Environment", $environment)
            .onAppear {
                if let environmentstring = SharedReference.shared.environment {
                    environment = environmentstring
                }
            }
            .onChange(of: environment) {
                SharedReference.shared.environment = environment
                saveConfiguration()
            }
    }

    var setenvironmenvariable: some View {
        EditValueScheme(400, "Environment variable", $environmentvalue)
            .onAppear {
                if let environmentvaluestring = SharedReference.shared.environmentvalue {
                    environmentvalue = environmentvaluestring
                }
            }
            .onChange(of: environmentvalue) {
                SharedReference.shared.environmentvalue = environmentvalue
                saveConfiguration()
            }
    }
}
