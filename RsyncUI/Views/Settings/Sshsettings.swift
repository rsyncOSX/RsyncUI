//
//  Sshsettings.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 10/02/2021.
//
// swiftlint:disable line_length

import Combine
import OSLog
import SwiftUI

struct Sshsettings: View {
    @Environment(AlertError.self) private var alerterror

    @State private var usersettings = ObservableSSH()
    @State private var localsshkeys: Bool = false
    @State private var showcopykeys: Bool = false
    // Combine for debounce of sshport and keypath
    @State var publisherport = PassthroughSubject<String, Never>()
    @State var publisherkeypath = PassthroughSubject<String, Never>()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                ToggleViewDefault(NSLocalizedString("Local ssh keys are present", comment: ""), $localsshkeys)
                    .disabled(true)

                setsshpath

                setsshport
            }
            .onAppear(perform: {
                localsshkeys = SshKeys().validatepublickeypresent()
                Task {
                    try await Task.sleep(seconds: 3)
                    Logger.process.info("SSH settings is DEFAULT")
                    SharedReference.shared.settingsischanged = false
                    usersettings.ready = true
                }
            })
            .onChange(of: SharedReference.shared.settingsischanged) {
                guard SharedReference.shared.settingsischanged == true,
                      usersettings.ready == true else { return }
                Task {
                    try await Task.sleep(seconds: 3)
                    _ = WriteUserConfigurationJSON(UserConfiguration())
                    SharedReference.shared.settingsischanged = false
                    Logger.process.info("Usersettings is SAVED")
                }
            }
            .alert(isPresented: $usersettings.alerterror,
                   content: { Alert(localizedError: usersettings.error)
                   })
            .toolbar {
                ToolbarItem {
                    Button {
                        createkeys()
                    } label: {
                        Image(systemName: "key")
                            .foregroundColor(Color(.blue))
                            .imageScale(.large)
                    }
                    .help("Create keys")
                }

                ToolbarItem {
                    Button {
                        showcopykeys = true
                    } label: {
                        Image(systemName: "arrow.forward.circle")
                            .foregroundColor(Color(.blue))
                            .imageScale(.large)
                    }
                    .help("Show copy keys")
                }

                ToolbarItem {
                    if SharedReference.shared.settingsischanged && usersettings.ready { thumbsupgreen }
                }
            }
        }
        .navigationDestination(isPresented: $showcopykeys) {
            ShowSSHCopyKeysView()
        }
    }

    var thumbsupgreen: some View {
        Label("", systemImage: "hand.thumbsup")
            .foregroundColor(Color(.green))
            .padding()
    }

    var setsshpath: some View {
        EditValue(250, NSLocalizedString("Global ssh keypath and identityfile", comment: ""), $usersettings.sshkeypathandidentityfile)
            .onAppear(perform: {
                if let sshkeypath = SharedReference.shared.sshkeypathandidentityfile {
                    usersettings.sshkeypathandidentityfile = sshkeypath
                }
            })
            .onChange(of: usersettings.sshkeypathandidentityfile) {
                publisherkeypath.send(usersettings.sshkeypathandidentityfile)
            }
            .onReceive(
                publisherkeypath.debounce(
                    for: .seconds(2),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                usersettings.sshkeypath(usersettings.sshkeypathandidentityfile)
            }
    }

    var setsshport: some View {
        EditValue(250, NSLocalizedString("Global ssh port", comment: ""),
                  $usersettings.sshportnumber)
            .onAppear(perform: {
                if let sshport = SharedReference.shared.sshport {
                    usersettings.sshportnumber = String(sshport)
                }
            })
            .onChange(of: usersettings.sshportnumber) {
                publisherport.send(usersettings.sshportnumber)
            }
            .onReceive(
                publisherport.debounce(
                    for: .seconds(1),
                    scheduler: DispatchQueue.main
                )
            ) { _ in
                usersettings.sshport(usersettings.sshportnumber)
            }
    }
}

extension Sshsettings: @unchecked Sendable {
    func createkeys() {
        Task {
            if await SshKeys().createPublicPrivateRSAKeyPair() {
                localsshkeys = SshKeys().validatepublickeypresent()
            }
        }
    }
}

// swiftlint:enable line_length
