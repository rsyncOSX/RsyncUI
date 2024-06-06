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
    // Settings are changed
    @State var settings: Bool = false

    var body: some View {
        Form {
            Section {
                setenvironment

                setenvironmenvariable
            } header: {
                Text("Rsync environment")
            }
        }
        .onAppear(perform: {
            Task {
                try await Task.sleep(seconds: 1)
                Logger.process.info("Environmentsettings is DEFAULT")
                SharedReference.shared.settingsischanged = false
                settings = true
            }
        })
        .onChange(of: SharedReference.shared.settingsischanged) {
            guard SharedReference.shared.settingsischanged == true else { return }
            Task {
                try await Task.sleep(seconds: 1)
                _ = WriteUserConfigurationJSON(UserConfiguration())
                SharedReference.shared.settingsischanged = false
                Logger.process.info("Environmentsettings is SAVED")
            }
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    var setenvironment: some View {
        EditValue(250, NSLocalizedString("Environment", comment: ""), $environment)
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
        EditValue(250, NSLocalizedString("Environment variable", comment: ""), $environmentvalue)
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

/*
 .toolbar {
     ToolbarItem {
         if SharedReference.shared.settingsischanged { thumbsupgreen }
     }
 }
 */
