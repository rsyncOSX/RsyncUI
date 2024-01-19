//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import OSLog
import SwiftUI

struct Othersettings: View {
    @State private var environmentvalue: String = ""
    @State private var environment: String = ""

    var body: some View {
        Form {
            Spacer()

            ZStack {
                HStack {
                    // For center
                    Spacer()

                    // Column 1
                    VStack(alignment: .leading) {
                        setenvironment

                        setenvironmenvariable
                    }.padding()

                    Spacer()
                }
            }
            // Save button right down corner
            Spacer()
        }
        .lineSpacing(2)
        .onDisappear(perform: {
            if SharedReference.shared.settingsischanged {
                Logger.process.info("Othersettings is SAVED")
                // _ = WriteUserConfigurationJSON(UserConfiguration())
            }
            SharedReference.shared.settingsischanged = false
        })
        .onAppear(perform: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                Logger.process.info("Othersettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
            }
        })
    }

    var setenvironment: some View {
        EditValue(350, NSLocalizedString("Environment", comment: ""), $environment)
            .onAppear(perform: {
                if let environmentstring = SharedReference.shared.environment {
                    environment = environmentstring
                }
            })
            .onChange(of: environment) {
                SharedReference.shared.environment = environment
            }
    }

    var setenvironmenvariable: some View {
        EditValue(350, NSLocalizedString("Environment variable", comment: ""), $environmentvalue)
            .onAppear(perform: {
                if let environmentvaluestring = SharedReference.shared.environmentvalue {
                    environmentvalue = environmentvaluestring
                }
            })
            .onChange(of: environmentvalue) {
                SharedReference.shared.environmentvalue = environmentvalue
            }
    }
}
