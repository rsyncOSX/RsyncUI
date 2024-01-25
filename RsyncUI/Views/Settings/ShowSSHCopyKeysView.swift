//
//  ShowSSHCopyKeysView.swift
//  RsyncUI
//
//  Created by Thomas Evensen on 24/01/2024.
//

import SwiftUI

struct ShowSSHCopyKeysView: View {
    @Binding var selectedprofile: String?
    @State private var selectedlogin: UniqueserversandLogins?

    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedlogin) {
                ForEach(rsyncUIdata.getuniqueserversandlogins() ?? []) { record in
                    ServerRow(record: record)
                        .tag(record)
                }
            }
            .frame(width: 250, height: 100)

            if selectedlogin == nil {
                defaultstrings
            } else {
                strings
            }
        }
    }

    var rsyncUIdata: RsyncUIconfigurations {
        let configurationsdata = ReadConfigurationsfromstore(selectedprofile)
        return RsyncUIconfigurations(selectedprofile,
                                     configurationsdata.configurations ?? [],
                                     configurationsdata.validhiddenIDs)
    }

    // Copy strings
    var strings: some View {
        VStack {
            Text(SshKeys().verifyremotekey(remote: selectedlogin))
            Text(SshKeys().copylocalpubrsakeyfile(remote: selectedlogin))
        }
        .textSelection(.enabled)
    }

    // Default strings

    var defaultstrings: some View {
        VStack {
            Text("Test SSH")
            Text("Copy strings")
        }
    }
}

struct ServerRow: View {
    var record: UniqueserversandLogins

    var body: some View {
        HStack {
            Text(record.offsiteUsername ?? "")
                .modifier(FixedTag(80, .leading))
            Text(record.offsiteServer ?? "")
                .modifier(FixedTag(80, .leading))
        }
    }
}

struct UniqueserversandLogins: Hashable, Identifiable {
    var id = UUID()
    var offsiteUsername: String?
    var offsiteServer: String?

    init(_ username: String,
         _ servername: String)
    {
        offsiteServer = servername
        offsiteUsername = username
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(offsiteUsername)
        hasher.combine(offsiteServer)
    }
}
