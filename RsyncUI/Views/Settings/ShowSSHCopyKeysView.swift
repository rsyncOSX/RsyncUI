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
        HStack {
            uniqueuserversandloginslist

            if selectedlogin != nil { strings }
        }
    }

    var rsyncUIdata: RsyncUIconfigurations {
        let configurationsdata = ReadConfigurationsfromstore(selectedprofile)
        return RsyncUIconfigurations(selectedprofile,
                                     configurationsdata.configurations ?? [],
                                     configurationsdata.validhiddenIDs)
    }

    var uniqueuserversandloginslist: some View {
        List(selection: $selectedlogin) {
            ForEach(rsyncUIdata.getuniqueserversandlogins() ?? []) { record in
                ServerRow(record: record)
                    .tag(record)
            }
        }
        .frame(width: 250, height: 100)
    }

    var verifystring: String {
        if let login = selectedlogin {
            return SshKeys().verifyremotekey(remote: login)
        } else {
            return ""
        }
    }

    var copystring: String {
        if let login = selectedlogin {
            return SshKeys().copylocalpubrsakeyfile(remote: login)
        } else {
            return ""
        }
    }

    // Copy strings
    var strings: some View {
        VStack(alignment: .leading) {
            Text(verifystring)
            Text(copystring)
        }
        .textSelection(.enabled)
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
