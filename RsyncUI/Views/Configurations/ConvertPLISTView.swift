//
//  ConvertPLISTView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import SwiftUI

struct ConvertPLISTView: View {
    @EnvironmentObject var rsyncUIData: RsyncUIdata
    @Binding var reload: Bool
    // Documents about convert
    var infoaboutconvert: String = "https://rsyncui.netlify.app/post/plist/"
    @State private var jsonfileexists: Bool = false
    @State private var convertisconfirmed: Bool = false
    @State private var convertcompleted: Bool = false

    @State private var backup: Bool = false

    var body: some View {
        VStack {
            Text(NSLocalizedString("Convert from PLIST for", comment: "OutputRsyncView"))
                .font(.title2)
            Text(rsyncUIData.profile ?? NSLocalizedString("Default profile", comment: "default profile"))
                .font(.title2)
                .foregroundColor(Color.blue)
                .padding()

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

            Spacer()

            HStack {
                Spacer()
            }
        }
        .padding()
    }

    var prepareconvertplist: some View {
        HStack {
            Button(NSLocalizedString("Info about convert", comment: "Othersettings")) { openinfo() }
                .buttonStyle(PrimaryButtonStyle())

            ToggleView(NSLocalizedString("Confirm convert", comment: "Othersettings"), $convertisconfirmed.onChange {
                verifyconvert()
            })

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

    var convertbutton: some View {
        Button(NSLocalizedString("PLIST", comment: "Othersettings")) { verifyconvert() }
            .buttonStyle(PrimaryButtonStyle())
    }

    func verifyconvert() {
        let configs = ReadConfigurationsPLIST(rsyncUIData.profile)
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
