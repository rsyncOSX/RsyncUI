//
//  SettingsView.swift
//  RsyncSwiftUI
//
//  Created by Thomas Evensen on 01/02/2021.
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedprofile: String?

    var body: some View {
        TabView {
            Usersettings()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            Sshsettings(uniqueserversandlogins: ReadConfigurationJSON(profile).getuniqueserversandlogins() ?? [])
                .tabItem {
                    Label("Ssh", systemImage: "terminal")
                }
            Othersettings()
                .tabItem {
                    Label("Environment", systemImage: "gear")
                }
            AboutView()
                .tabItem {
                    Label("Info", systemImage: "info.circle.fill")
                }
        }
        .padding()
        .frame(minWidth: 800, minHeight: 450)
        .onAppear {
            Task {
                await Rsyncversion().getrsyncversion()
            }
        }
    }

    var profile: String? {
        if selectedprofile == SharedReference.shared.defaultprofile || selectedprofile == nil {
            return nil
        } else {
            return selectedprofile
        }
    }
}

final class AlertError: ObservableObject {
    @Published private(set) var activeError: Error?

    func alert(error: Error) {
        DispatchQueue.main.async {
            self.activeError = error
        }
    }

    var presentalert: Binding<Bool> {
        return Binding<Bool>(
            get: { self.activeError != nil },
            set: { value in
                guard !value else { return }
                self.activeError = nil
            }
        )
    }
}

extension Alert {
    init(localizedError: Error) {
        self = Alert(nsError: localizedError as NSError)
    }

    init(nsError: NSError) {
        let message: Text? = {
            let message = [nsError.localizedFailureReason,
                           nsError.localizedRecoverySuggestion]
                .compactMap { $0 }.joined(separator: "\n\n")
            return message.isEmpty ? nil : Text(message)
        }()
        self = Alert(title: Text(nsError.localizedDescription),
                     message: message,
                     dismissButton: .default(Text("OK")))
    }
}
