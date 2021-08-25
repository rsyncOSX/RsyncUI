//
//  ConvertPLISTView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 17/06/2021.
//

import AlertToast
import SwiftUI

struct ConvertPLISTView: View {
    @EnvironmentObject var rsyncUIdata: RsyncUIdata
    @Binding var reload: Bool
    // Documents about convert
    var infoaboutconvert: String = "https://rsyncui.netlify.app/post/plist/"
    @State private var jsonfileexists: Bool = false
    @State private var convertisconfirmed: Bool = false
    @State private var convertcompleted: Bool = false

    @State private var backup: Bool = false

    var body: some View {
        VStack {
            HStack {
                Text("Convert from PLIST for:")
                    .font(.title2)
                Text(rsyncUIdata.profile ?? "Default profile")
                    .font(.title2)
                    .foregroundColor(Color.blue)
            }
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
                           title: Optional(NSLocalizedString("Completed", comment: "")), subTitle: Optional(""))
                    .onAppear(perform: {
                        // Show updated for 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            convertcompleted = false
                        }
                    })
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

            Spacer()

            HStack {
                Spacer()
            }
        }
        .padding()
    }

    var prepareconvertplist: some View {
        VStack {
            Button("Info about convert") { openinfo() }
                .buttonStyle(PrimaryButtonStyle())

            ToggleViewDefault(NSLocalizedString("Confirm convert", comment: ""), $convertisconfirmed.onChange {
                verifyconvert()
            })

            if convertisconfirmed {
                VStack {
                    // Backup configuration files
                    Button("Backup") { backupuserconfigs() }
                        .buttonStyle(PrimaryButtonStyle())

                    Button("Convert") { convert() }
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }

    var alertjsonfileexists: some View {
        AlertToast(type: .error(Color.red), title: Optional(NSLocalizedString("JSON file exists", comment: "")),
                   subTitle: Optional(""))
    }

    var convertbutton: some View {
        Button("PLIST") { verifyconvert() }
            .buttonStyle(PrimaryButtonStyle())
    }

    func verifyconvert() {
        guard jsonfileexists == false else {
            jsonfileexists = false
            return
        }
        let configs = ReadConfigurationsPLIST(rsyncUIdata.profile)
        if configs.jsonfileexist == true {
            jsonfileexists = true
        }
    }

    func convert() {
        let configs = ReadConfigurationsPLIST(rsyncUIdata.profile)
        let schedules = ReadSchedulesPLIST(rsyncUIdata.profile)
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
