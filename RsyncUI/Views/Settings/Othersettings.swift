//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//
import AlertToast
import SwiftUI

struct Othersettings: View {
    @StateObject var usersettings = ObserveablePath()
    @State private var backup: Bool = false

    var body: some View {
        Form {
            ZStack {
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

                    Spacer()
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Saved", comment: "")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                backup = false
                            }
                        })
                }
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
                Button("Save") { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Save") {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!usersettings.isDirty)
    }

    // Environment
    var headerenvironment: some View {
        Text("Environment")
    }

    // Paths
    var headerpaths: some View {
        Text("Paths for apps")
    }

    var setenvironment: some View {
        EditValue(250, NSLocalizedString("Environment", comment: ""),
                  $usersettings.environment.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let environment = SharedReference.shared.environment {
                    usersettings.environment = environment
                }
            })
    }

    var setenvironmenvariable: some View {
        EditValue(250, NSLocalizedString("Environment variable", comment: ""),
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
        EditValue(250, NSLocalizedString("Path to RsyncUI", comment: ""),
                  $usersettings.pathrsyncui.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let pathrsyncui = SharedReference.shared.pathrsyncui {
                    usersettings.pathrsyncui = pathrsyncui
                }
            })
    }

    var setpathtorsyncschedule: some View {
        EditValue(250, NSLocalizedString("Path to RsyncSchedule", comment: ""),
                  $usersettings.pathrsyncschedule.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let pathrsyncschedule = SharedReference.shared.pathrsyncschedule {
                    usersettings.pathrsyncschedule = pathrsyncschedule
                }
            })
    }
}

extension Othersettings {
    func saveusersettings() {
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        _ = WriteUserConfigurationPLIST()
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }
}
