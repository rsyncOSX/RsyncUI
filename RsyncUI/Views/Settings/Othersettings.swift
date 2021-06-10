//
//  Othersettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 03/03/2021.
//

import SwiftUI

struct Othersettings: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @StateObject var usersettings = ObserveablePath()

    @Binding var reload: Bool

    // Documents about convert
    var infoaboutconvert: String = "https://rsyncui.netlify.app/post/plist/"
    @State private var convertisready: Bool = false
    @State private var jsonfileexists: Bool = false
    @State private var convertisconfirmed: Bool = false
    @State private var convertcompleted: Bool = false
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

                if convertcompleted == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Completed",
                                                                 comment: "settings")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                convertcompleted = false
                            }
                        })
                }

                if backup == true {
                    AlertToast(type: .complete(Color.green),
                               title: Optional(NSLocalizedString("Saved",
                                                                 comment: "settings")), subTitle: Optional(""))
                        .onAppear(perform: {
                            // Show updated for 1 second
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                backup = false
                            }
                        })
                }
            }

            if convertisready {
                HStack {
                    Spacer()

                    prepareconvertplist

                    Spacer()
                }

                HStack {
                    Spacer()

                    if jsonfileexists { alertjsonfileexists }

                    Spacer()
                }
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
        .onAppear(perform: {
            convertisready = false
        })
    }

    // Save usersetting is changed
    var usersetting: some View {
        HStack {
            if usersettings.isDirty {
                Button(NSLocalizedString("Save", comment: "Othersettings")) { saveusersettings() }
                    .buttonStyle(PrimaryButtonStyle())
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.red, lineWidth: 5)
                    )
            } else {
                Button(NSLocalizedString("Save", comment: "Othersettings")) {}
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .disabled(!usersettings.isDirty)
    }

    var convertbutton: some View {
        Button(NSLocalizedString("PLIST", comment: "Othersettings")) { verifyconvert() }
            .buttonStyle(PrimaryButtonStyle())
    }

    // Environment
    var headerenvironment: some View {
        Text(NSLocalizedString("Environment", comment: "Othersettings"))
    }

    // Paths
    var headerpaths: some View {
        Text(NSLocalizedString("Paths for apps", comment: "Othersettings"))
    }

    var setenvironment: some View {
        EditValue(250, NSLocalizedString("Environment", comment: "Othersettings"),
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
        EditValue(250, NSLocalizedString("Environment variable", comment: "Othersettings"),
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
        EditValue(250, NSLocalizedString("Path to RsyncUI", comment: "Othersettings"),
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
        EditValue(250, NSLocalizedString("Path to RsyncSchedule", comment: "Othersettings"),
                  $usersettings.pathrsyncschedule.onChange {
                      usersettings.inputchangedbyuser = true
                  })
            .onAppear(perform: {
                if let pathrsyncschedule = SharedReference.shared.pathrsyncschedule {
                    usersettings.pathrsyncschedule = pathrsyncschedule
                }
            })
    }

    var prepareconvertplist: some View {
        HStack {
            Button(NSLocalizedString("Info about convert", comment: "Othersettings")) { openinfo() }
                .buttonStyle(PrimaryButtonStyle())

            ToggleView(NSLocalizedString("Confirm convert", comment: "Othersettings"), $convertisconfirmed)

            if convertisconfirmed {
                VStack {
                    // Backup configuration files
                    Button(NSLocalizedString("Backup", comment: "usersetting")) { backupuserconfigs() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button(NSLocalizedString("Convert", comment: "Othersettings")) { convert() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    var alertjsonfileexists: some View {
        AlertToast(type: .error(Color.red), title: Optional("JSON file exists"), subTitle: Optional(""))
    }
}

extension Othersettings {
    func saveusersettings() {
        usersettings.isDirty = false
        usersettings.inputchangedbyuser = false
        _ = WriteUserConfigurationPLIST()
    }

    func verifyconvert() {
        let configs = ReadConfigurationsPLIST(rsyncUIData.profile)
        if configs.thereisplistdata == true {
            convertisready = true
        }
        if configs.jsonfileexist == true {
            jsonfileexists = true
        }
    }

    func convert() {
        let configs = ReadConfigurationsPLIST(rsyncUIData.profile)
        let schedules = ReadSchedulesPLIST(rsyncUIData.profile)
        if convertisconfirmed {
            configs.writedatatojson()
            schedules.writedatatojson()
        }
        convertisready = false
        jsonfileexists = false
        convertisconfirmed = false
        convertcompleted = true
        reload = true
    }

    func openinfo() {
        NSWorkspace.shared.open(URL(string: infoaboutconvert)!)
    }

    func backupuserconfigs() {
        _ = Backupconfigfiles()
        backup = true
    }
}
