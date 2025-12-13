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

    var body: some View {
        Form {
            Section(header: Text("Rsync environment")
                .font(.title3)
                .fontWeight(.bold)) {
                    setenvironment

                    setenvironmenvariable
                }

            Section(header: Text("Save userconfiguration")
                .font(.title3)
                .fontWeight(.bold)) {
                    ConditionalGlassButton(
                        systemImage: "square.and.arrow.down",
                        text: "Save",
                        helpText: "Save userconfiguration"
                    ) {
                        _ = WriteUserConfigurationJSON(UserConfiguration())
                    }
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
            }
    }
}
