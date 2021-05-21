//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import SwiftUI

struct Othersettings: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var usersettings = ObserveableReferencePaths()

    var body: some View {
        Form {
            HStack {
                // For center
                Spacer()
                // Column 1
                VStack(alignment: .leading) {
                    Section(header: headerpaths) {
                        setpathtorsyncui

                        setpathtorsyncschedule
                    }
                }.padding()

                // Column 2
                VStack(alignment: .leading) {
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

                convertbutton

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

    var convertbutton: some View {
        Button(NSLocalizedString("Convert", comment: "usersetting")) { convert() }
            .buttonStyle(PrimaryButtonStyle())
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
        EditValue(250, NSLocalizedString("Environment", comment: "settings"), $usersettings.environment.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let environment = SharedReference.shared.environment {
                    usersettings.environment = environment
                }
            })
    }

    var setenvironmenvariable: some View {
        EditValue(250, NSLocalizedString("Environment variable", comment: "settings"),
                  $usersettings.environmentvalue.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let environmentvalue = SharedReference.shared.environmentvalue {
                    usersettings.environmentvalue = environmentvalue
                }
            })
    }

    var setpathtorsyncui: some View {
        EditValue(250, NSLocalizedString("Path to RsyncUI", comment: "settings"), $usersettings.pathrsyncui.onChange {
            usersettings.inputchangedbyuser = true
        })
            .onAppear(perform: {
                if let pathrsyncui = SharedReference.shared.pathrsyncui {
                    usersettings.pathrsyncui = pathrsyncui
                }
            })
    }

    var setpathtorsyncschedule: some View {
        EditValue(250, NSLocalizedString("Path to RsyncSchedule", comment: "settings"),
                  $usersettings.pathrsyncschedule.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let pathrsyncschedule = SharedReference.shared.pathrsyncschedule {
                    usersettings.pathrsyncschedule = pathrsyncschedule
                }
            })
    }

    func saveusersettings() {
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        _ = WriteUserConfigurationPLIST()
    }

    func convert() {
        //  _ = ReadConfigurationsPLIST(rsyncUIData.profile)
        // _ = ReadSchedulesPLIST(rsyncUIData.profile)
    }
}
