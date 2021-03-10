//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import SwiftUI

struct Othersettings: View {
    @StateObject var usersettings = ObserveableReference()

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerpaths) {
                        setpathtorsyncosx

                        setpathtorsyncosxsched
                    }

                    Section(header: headerenvironment) {
                        setenvironment

                        setenvironmenvariable
                    }
                }.padding()

                // For center
                Spacer()
            }
            // Save button right down corner
            Spacer()

            HStack {
                Spacer()

                usersetting
            }
        }
        .lineSpacing(2)
        .padding()
    }

    // Save usersetting is changed
    var usersetting: some View {
        HStack {
            if usersettings.isDirty {
                Button(NSLocalizedString("Save", comment: "usersetting")) { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "usersetting")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!usersettings.isDirty)
    }

    // Environment
    var headerenvironment: some View {
        Text(NSLocalizedString("Environment", comment: "other settings"))
    }

    // Paths
    var headerpaths: some View {
        Text(NSLocalizedString("Paths for apps", comment: "ssh settings"))
    }

    var setenvironment: some View {
        EditValue(250, NSLocalizedString("Environment", comment: "settings"), $usersettings.environment)
            .onAppear(perform: {
                if let environment = SharedReference.shared.environment {
                    usersettings.environment = environment
                }
            })
    }

    var setenvironmenvariable: some View {
        EditValue(250, NSLocalizedString("Environment variable", comment: "settings"), $usersettings.environmentvalue)
            .onAppear(perform: {
                if let environmentvalue = SharedReference.shared.environmentvalue {
                    usersettings.environmentvalue = environmentvalue
                }
            })
    }

    var setpathtorsyncosx: some View {
        EditValue(250, NSLocalizedString("Path to RsyncUI", comment: "settings"), $usersettings.pathrsyncosx)
            .onAppear(perform: {
                if let pathrsyncosx = SharedReference.shared.pathrsyncosx {
                    usersettings.pathrsyncosx = pathrsyncosx
                }
            })
    }

    var setpathtorsyncosxsched: some View {
        EditValue(250, NSLocalizedString("Path to RsyncOSXsched", comment: "settings"), $usersettings.pathrsyncosxsched)
            .onAppear(perform: {
                if let pathrsyncosxsched = SharedReference.shared.pathrsyncosxsched {
                    usersettings.pathrsyncosxsched = pathrsyncosxsched
                }
            })
    }

    func saveusersettings() {
        usersettings.isDirty = false
        PersistentStorageUserconfiguration().saveuserconfiguration()
    }
}
